//
//  CommunityMessageViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 24/02/25.
//

import Foundation
import AVFoundation
import SwiftUI

@MainActor
class CommunityMessageViewModel: ObservableObject {
    
    private var audioPlayer: AVAudioPlayer?
    private var receivedMessageIds: [String] = []
    
    @Published var formattedMessages: [FormattedCommunityMessage] = []
    @Published var intermediaryMessages: [CommunityMessageIntermediary] = [] {
        didSet {
            formatMessages()
        }
    }
    @Published var receivedMessages: [CommunityMessage] = []
    
    @Published var messageText: String = ""
    @Published var overlayError: (Bool, LocalizedStringKey) = (false, "")
    @Published var repliedMessage: FormattedCommunityMessage?
    @Published var messageTimer: Timer?
    @Published var highlightedMessageId: String?
    @Published var lastMessageAdded: String?
    
//    @Published var latitude: Double = 0
//    @Published var longitude: Double = 0
    
    //MARK: - Fetch Messages
    
    func getMessages(communityId: String, token: String) async {
        let result = await AYServices.shared.getCommunityMessages(communityId: communityId, timestamp: intermediaryMessages.first?.createdAt, token: token)
        
        switch result {
        case .success(let messages):
            self.intermediaryMessages.insert(contentsOf: convertReceivedMessages(messages), at: 0)
        case .failure:
            overlayError = (true, ErrorMessage.getMessages)
        }
    }
    
    func getLastMessages(communityId: String, token: String) async {
        let result = await AYServices.shared.getCommunityMessages(communityId: communityId, timestamp: nil, token: token)
        
        switch result {
        case .success(let messages):
            self.intermediaryMessages = convertReceivedMessages(messages)
        case .failure:
            overlayError = (true, ErrorMessage.getMessages)
        }
    }
    
    private func convertReceivedMessages(_ messages: [CommunityMessage]) -> [CommunityMessageIntermediary] {
        var convertedMessages: [CommunityMessageIntermediary] = []
        for message in messages {
            let intermediaryMessage = message.convertMessageToIntermediary(forCurrentUserUid: LocalState.currentUserUid)
            convertedMessages.append(intermediaryMessage)
        }
        return convertedMessages
    }
    
    //MARK: - Send Message
    
    func sendMessage(forCommunityId communityId: String, text: String, repliedMessage: FormattedCommunityMessage?, location: Location, token: String) async {
        resetInputs()
        let messagesToBeSent = getMessagesToBeSent(communityId: communityId, text: text, repliedMessage: repliedMessage)
        displayMessages(fromArray: messagesToBeSent)
        await withTaskGroup(of: Void.self) { group in
            for message in messagesToBeSent {
                group.addTask {
                    await self.sendMessage(message, location: location, token: token)
                }
            }
        }
    }
    
    private func resetInputs() {
        self.repliedMessage = nil
        self.messageText = ""
    }
    
    private func getMessagesToBeSent(communityId: String, text: String, repliedMessage: FormattedCommunityMessage?) -> [CommunityMessageIntermediary] {
        var messages: [CommunityMessageIntermediary] = []
        
        let message = CommunityMessageIntermediary(id: UUID().uuidString, communityId: communityId, text: text, createdAt: Int(Date().timeIntervalSince1970), isCurrentUser: true, senderUserUid: LocalState.currentUserUid, senderUsername: "")
        messages.append(message)
        
        messages[0].repliedMessageId = repliedMessage?.id
        messages[0].repliedMessageText = repliedMessage?.text
        
        return messages
    }
    
    private func displayMessages(fromArray messages: [CommunityMessageIntermediary]) {
        for message in messages {
            intermediaryMessages.append(message)
            self.lastMessageAdded = message.id
        }
    }
    
    private func sendMessage(_ message: CommunityMessageIntermediary, location: Location, token: String) async {
        await postNewMessage(withTemporaryId: message.id, communityId: message.communityId, text: message.text, repliedMessageId: message.repliedMessageId, repliedMessageText: message.repliedMessageText, location: location, token: token)
    }
    
    private func postNewMessage(withTemporaryId tempId: String, communityId: String, text: String, repliedMessageId: String?, repliedMessageText: String?, location: Location, token: String) async {
        let result = await AYServices.shared.postCommunityMessage(communityId: communityId, latitude: location.latitude, longitude: location.longitude, text: text, repliedMessageId: repliedMessageId, token: token)
        
        switch result {
        case .success(let message):
            playSendMessageSound()
            updateMessage(withId: tempId, toStatus: .sent)
            updateMessage(withId: tempId, toPostedMessage: message)
        case .failure:
            updateMessage(withId: tempId, toStatus: .failed)
            overlayError = (true, ErrorMessage.sendMessage)
        }
    }
    
    private func updateMessage(withId messageId: String, toStatus newStatus: MessageStatus) {
        if let index = intermediaryMessages.firstIndex(where: { $0.id == messageId }) {
            intermediaryMessages[index].status = newStatus
        } else {
            print("❌ Error: Message with ID \(messageId) was not found.")
        }
    }
    
    private func updateMessage(withId messageId: String, toPostedMessage message: CommunityMessage) {
        if let index = intermediaryMessages.firstIndex(where: { $0.id == messageId }) {
            intermediaryMessages[index].createdAt = message.createdAt
            intermediaryMessages[index].id = message._id
        } else {
            print("❌ Error: Message with ID \(messageId) was not found.")
        }
    }
    
    private func playSendMessageSound() {
        playSound(withName: "sent-message-sound")
    }
    
    func resendMessage(withTempId tempId: String, location: Location, token: String) async {
        if let message = getMessage(withId: tempId) {
            await postNewMessage(withTemporaryId: tempId, communityId: message.communityId, text: message.text, repliedMessageId: message.repliedMessageId, repliedMessageText: message.repliedMessageText, location: location, token: token)
        }
    }
    
    func getMessage(withId messageId: String) -> FormattedCommunityMessage? {
        if let index = formattedMessages.firstIndex(where: { $0.id == messageId }) {
            return formattedMessages[index]
        } else {
            return nil
        }
    }
    
    //MARK: - Receive Message
    
    func processSocketMessage(_ data: [Any], toChat communityId: String,  emitReadCommand: (String) -> ()) {
        let newMessage = decodeMessage(data)
        if let msg = newMessage, !msg.isCurrentUser, !wasMessageReceived(msg), msg.communityId == communityId {
            DispatchQueue.main.async {
                self.intermediaryMessages.append(msg)
                self.lastMessageAdded = msg.id
                self.playReceivedMessageSound(forMessageId: msg.id)
            }
            emitReadCommand(msg.id)
        }
    }
    
    private func wasMessageReceived(_ message: CommunityMessageIntermediary) -> Bool {
        return intermediaryMessages.contains { $0.id == message.id }
    }
    
    func decodeMessage(_ message: [Any]) -> CommunityMessageIntermediary? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: message[0], options: [])
            let newMessage = try JSONDecoder().decode(CommunityMessage.self, from: jsonData)
            return newMessage.convertMessageToIntermediary(forCurrentUserUid: LocalState.currentUserUid)
        } catch {
            print(error)
        }
        return nil
    }
    
    private func playReceivedMessageSound(forMessageId messageId: String) {
        if !receivedMessageIds.contains(messageId) {
            receivedMessageIds.append(messageId)
            print("🎶 Playing sound for messageId: \(messageId)")
            playSound(withName: "received-message-sound")
        }
    }
    
    //MARK: - Delete Message
    
    func deleteMessage(messageId: String, token: String) async {
        let result = await AYServices.shared.deleteCommunityMessage(communityMessageId: messageId, token: token)
        
        switch result {
        case .success:
            removeMessage(withId: messageId)
        case .failure:
            overlayError = (true, ErrorMessage.deleteMessage)
        }
    }
    
    private func removeMessage(withId messageId: String) {
        intermediaryMessages.removeAll { $0.id == messageId }
    }
    
    //MARK: - Format Messages
    
    private func formatMessages() {
        var messages: [FormattedCommunityMessage] = []
        for (index, message) in intermediaryMessages.enumerated() {
            let formattedMessage = message.formatMessage(
                isFirst: getTail(forMessage: message, withIndex: index),
                timeDivider: getTimeDivider(forMessage: message, withIndex: index),
                shouldDispaySenderUsername: shouldDispaySenderUsername(forMessage: message, withIndex: index),
                shouldDisplaySenderProfilePic: shouldDisplaySenderProfilePic(forMessage: message, withIndex: index)
            )
            messages.append(formattedMessage)
        }
        self.formattedMessages = messages
    }
    
    private func getTail(forMessage message: CommunityMessageIntermediary, withIndex index: Int) -> Bool {
        guard index < intermediaryMessages.count - 1 else {
            return true
        }
        
        let nextMessage = intermediaryMessages[index + 1]
        let timeDifferenceSec = nextMessage.createdAt.timeIntervalSince1970InSeconds - message.createdAt.timeIntervalSince1970InSeconds
        return timeDifferenceSec >= 60
    }
    
    private func getTimeDivider(forMessage message: CommunityMessageIntermediary, withIndex index: Int) -> Int? {
        guard index > 0 else {
            return message.createdAt
        }
        
        let previousMessage = intermediaryMessages[index - 1]
        let timeDifferenceSec = message.createdAt.timeIntervalSince1970InSeconds - previousMessage.createdAt.timeIntervalSince1970InSeconds
        return timeDifferenceSec >= 3600 ? message.createdAt : nil
    }
    
    private func shouldDispaySenderUsername(forMessage message: CommunityMessageIntermediary, withIndex index: Int) -> Bool {
        guard index > 0 else {
            return !message.isCurrentUser
        }
        
        let previousMessage = intermediaryMessages[index - 1]
        let isMessageSenderDifferentFromPrevious = previousMessage.senderUserUid != message.senderUserUid
        let isCurrentUser = message.isCurrentUser
        return isMessageSenderDifferentFromPrevious && !isCurrentUser
    }
    
    private func shouldDisplaySenderProfilePic(forMessage message: CommunityMessageIntermediary, withIndex index: Int) -> Bool {
        if isTheLastMessage(forIndex: index) {
            return !message.isCurrentUser
        }
        
        let nextMessage = intermediaryMessages[index + 1]
        let isMessageSenderDifferentFromNext = nextMessage.senderUserUid != message.senderUserUid
        let isCurrentUser = message.isCurrentUser
        
        return isMessageSenderDifferentFromNext && !isCurrentUser
    }
    
    private func isTheLastMessage(forIndex index: Int) -> Bool {
        return index >= intermediaryMessages.count - 1
    }
    
    private func playSound(withName soundName: String) {
        guard let url = Bundle.main.url(forResource: soundName, withExtension: "mp3") else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            audioPlayer = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            guard let player = audioPlayer else { return }
            player.play()
        } catch let error {
            print(error.localizedDescription)
        }
    }
}
