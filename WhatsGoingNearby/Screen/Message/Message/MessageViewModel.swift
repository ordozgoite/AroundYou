//
//  MessageViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 28/03/24.
//

import Foundation
import SwiftUI
import PhotosUI
import FirebaseStorage
import AVFoundation

@MainActor
class MessageViewModel: ObservableObject {
    
    private var audioPlayer: AVAudioPlayer?
    private var receivedMessageIds: [String] = []
    
    @Published var formattedMessages: [FormattedMessage] = []
    @Published var intermediaryMessages: [MessageIntermediary] = [] {
        didSet {
            formatMessages()
        }
    }
    @Published var receivedMessages: [Message] = []
    
    @Published var messageText: String = ""
    @Published var overlayError: (Bool, LocalizedStringKey) = (false, "")
    @Published var repliedMessage: FormattedMessage?
    @Published var messageTimer: Timer?
    @Published var highlightedMessageId: String?
    @Published var lastMessageAdded: String?
    
    @Published var images: [UIImage] = []
    @Published var isCameraDisplayed = false
    @Published var isPhotosDisplayed = false
    
    func removeImage(fromIndex index: Int) {
        guard index < images.count else { return }
        self.images.remove(at: index)
    }
    
    //MARK: - Fetch Messages
    
    func getMessages(chatId: String, token: String) async {
        let result = await AYServices.shared.getMessages(chatId: chatId, timestamp: intermediaryMessages.first?.createdAt, token: token)
        
        switch result {
        case .success(let messages):
            self.intermediaryMessages.insert(contentsOf: convertReceivedMessages(messages), at: 0)
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
    }
    
    private func convertReceivedMessages(_ messages: [Message]) -> [MessageIntermediary] {
        var convertedMessages: [MessageIntermediary] = []
        for message in messages {
            let intermediaryMessage = message.convertMessageToIntermediary(forCurrentUserUid: LocalState.currentUserUid)
            convertedMessages.append(intermediaryMessage)
        }
        return convertedMessages
    }
    
    //MARK: - Send Message
    
    func sendMessage(forChat chatId: String, text: String?, images: [UIImage], repliedMessage: FormattedMessage?, token: String) async throws {
        resetInputs()
        let messagesToBeSent = getMessagesToBeSent(chatId: chatId, text: text, images: images, repliedMessage: repliedMessage)
        displayMessages(fromArray: messagesToBeSent)
        await withTaskGroup(of: Void.self) { group in
            for message in messagesToBeSent {
                group.addTask {
                    do {
                        try await self.sendMessage(message, token: token)
                    } catch {
                        print("Error sending message: \(error)")
                    }
                }
            }
        }
    }
    
    private func resetInputs() {
        self.repliedMessage = nil
        self.messageText = ""
        self.images = []
    }
    
    func sendImage(forChat chatId: String, image: UIImage, token: String) async throws {
        let messagesToBeSent = getMessagesToBeSent(chatId: chatId, text: nil, images: [image], repliedMessage: nil)
        displayMessages(fromArray: messagesToBeSent)
        if let message = messagesToBeSent.first {
            try await sendMessage(message, token: token)
        }
    }
    
    private func getMessagesToBeSent(chatId: String, text: String?, images: [UIImage], repliedMessage: FormattedMessage?) -> [MessageIntermediary] {
        var messages: [MessageIntermediary] = []
        
        for image in images {
            let message = MessageIntermediary(id: UUID().uuidString, chatId: chatId, text: nil, imageUrl: nil, isRead: false, createdAt: Int(Date().timeIntervalSince1970), repliedMessageId: nil, repliedMessageText: nil, status: .sending, image: image, isCurrentUser: true)
            messages.append(message)
        }
        
        if let text = text {
            let message = MessageIntermediary(id: UUID().uuidString, chatId: chatId, text: text, imageUrl: nil, isRead: false, createdAt: Int(Date().timeIntervalSince1970), repliedMessageId: nil, repliedMessageText: nil, status: .sending, image: nil, isCurrentUser: true)
            messages.append(message)
        }
        
        messages[0].repliedMessageId = repliedMessage?.id
        messages[0].repliedMessageText = repliedMessage?.message
        
        return messages
    }
    
    private func displayMessages(fromArray messages: [MessageIntermediary]) {
        for message in messages {
            intermediaryMessages.append(message)
            self.lastMessageAdded = message.id
        }
    }
    
    private func sendMessage(_ message: MessageIntermediary, token: String) async throws {
        let imageUrl = try await getUrl(forImage: message.image)
        await postNewMessage(withTemporaryId: message.id, chatId: message.chatId, text: message.text, imageUrl: imageUrl, repliedMessageId: message.repliedMessageId, repliedMessageText: message.repliedMessageText, token: token)
    }
    
    private func getUrl(forImage image: UIImage?) async throws -> String? {
        if let img = image {
            do {
                return try await storeImage(img)
            } catch {
                overlayError = (true, ErrorMessage.defaultErrorMessage)
            }
        }
        return nil
    }
    
    private func storeImage(_ image: UIImage) async throws -> String? {
        let storageRef = Storage.storage().reference()
        let fileRef = storageRef.child("post-image/\(UUID().uuidString).jpg")
        let imageData = image.jpegData(compressionQuality: 0.8)
        _ = try await fileRef.putDataAsync(imageData!)
        let imageUrl = try await fileRef.downloadURL()
        return imageUrl.absoluteString
    }
    
    private func postNewMessage(withTemporaryId tempId: String, chatId: String, text: String?, imageUrl: String?, repliedMessageId: String?, repliedMessageText: String?, token: String) async {
        let result = await AYServices.shared.postNewMessage(chatId: chatId, text: text, imageUrl: imageUrl, repliedMessageId: repliedMessageId, token: token)
        
        switch result {
        case .success(let message):
            playSendMessageSound()
            updateMessage(withId: tempId, toStatus: .sent)
            updateMessage(withId: tempId, toPostedMessage: message)
        case .failure:
            updateMessage(withId: tempId, toStatus: .failed)
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
    }
    
    private func updateMessage(withId messageId: String, toStatus newStatus: MessageStatus) {
        if let index = intermediaryMessages.firstIndex(where: { $0.id == messageId }) {
            intermediaryMessages[index].status = newStatus
        } else {
            print("❌ Error: Message with ID \(messageId) was not found.")
        }
    }
    
    private func updateMessage(withId messageId: String, toPostedMessage message: Message) {
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
    
    func resendMessage(withTempId tempId: String, token: String) async {
        if let message = getMessage(withId: tempId) {
            await postNewMessage(withTemporaryId: tempId, chatId: message.chatId, text: message.message, imageUrl: message.imageUrl, repliedMessageId: message.repliedMessageId, repliedMessageText: message.repliedMessageText, token: token)
        }
    }
    
    func getMessage(withId messageId: String) -> FormattedMessage? {
        if let index = formattedMessages.firstIndex(where: { $0.id == messageId }) {
            return formattedMessages[index]
        } else {
            return nil
        }
    }
    
    //MARK: - Receive Message
    
    func processMessage(fromData data: [Any]) {
        let newMessage = decodeMessage(data)
        if let msg = newMessage, !msg.isCurrentUser, !wasMessageReceived(msg) {
            DispatchQueue.main.async {
                self.intermediaryMessages.append(msg)
                self.playReceivedMessageSound(forMessageId: msg.id)
            }
        }
    }
    
    private func wasMessageReceived(_ message: MessageIntermediary) -> Bool {
        return intermediaryMessages.contains { $0.id == message.id }
    }
    
    func decodeMessage(_ message: [Any]) -> MessageIntermediary? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: message[0], options: [])
            let newMessage = try JSONDecoder().decode(Message.self, from: jsonData)
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
        let result = await AYServices.shared.deleteMessage(messageId: messageId, token: token)
        
        switch result {
        case .success:
            removeMessage(withId: messageId)
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
    }
    
    private func removeMessage(withId messageId: String) {
        intermediaryMessages.removeAll { $0.id == messageId }
    }
    
    //MARK: - Format Messages
    
    private func formatMessages() {
        var messages: [FormattedMessage] = []
        for (index, message) in intermediaryMessages.enumerated() {
            let formattedMessage = message.formatMessage(isFirst: getTail(forMessage: message, withIndex: index), timeDivider: getTimeDivider(forMessage: message, withIndex: index))
            messages.append(formattedMessage)
        }
        self.formattedMessages = messages
    }
    
    private func getTail(forMessage message: MessageIntermediary, withIndex index: Int) -> Bool {
        guard index < intermediaryMessages.count - 1 else {
            return true
        }
        
        let nextMessage = intermediaryMessages[index + 1]
        let timeDifferenceSec = nextMessage.createdAt.timeIntervalSince1970InSeconds - message.createdAt.timeIntervalSince1970InSeconds
        return timeDifferenceSec >= 60
    }
    
    private func getTimeDivider(forMessage message: MessageIntermediary, withIndex index: Int) -> Int? {
        guard index > 0 else {
            return message.createdAt
        }
        
        let previousMessage = intermediaryMessages[index - 1]
        let timeDifferenceSec = message.createdAt.timeIntervalSince1970InSeconds - previousMessage.createdAt.timeIntervalSince1970InSeconds
        return timeDifferenceSec >= 3600 ? message.createdAt : nil
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
