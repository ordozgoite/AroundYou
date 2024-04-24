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
    
    var socket = SocketService.shared.getSocket()
    private var audioPlayer: AVAudioPlayer?
    
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
    
    @Published var image: UIImage?
    @Published var isCameraDisplayed = false
    @Published var isPhotosDisplayed = false
    
    //MARK: - Fetch Messages
    
    func getMessages(chatId: String, token: String) async {
        let result = await AYServices.shared.getMessages(chatId: chatId, token: token)
        
        switch result {
        case .success(let messages):
//            self.receivedMessages = messages
            self.intermediaryMessages = convertReceivedMessages(messages)
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
    
    func sendMessage(withTemporaryId tempId: String = UUID().uuidString, chatId: String, text: String?, image: UIImage?, repliedMessage: FormattedMessage?, token: String) async throws {
        resetInputs()
        addMessageToScreen(withTemporaryId: tempId, chatId: chatId, text: text, image: image, repliedMessage: repliedMessage)
        let imageUrl = try await getUrl(forImage: image)
        await postNewMessage(withTemporaryId: tempId, chatId: chatId, text: text, imageUrl: imageUrl, repliedMessage: repliedMessage, token: token)
    }
    
    private func resetInputs() {
        self.repliedMessage = nil
        self.messageText = ""
        self.image = nil
    }
    
    private func addMessageToScreen(withTemporaryId tempId: String, chatId: String, text: String?, image: UIImage?, repliedMessage: FormattedMessage?) {
        let newMessage = MessageIntermediary(
            id: tempId,
            chatId: chatId,
            text: text,
            imageUrl: nil,
            isRead: false,
            createdAt: Int(Date().timeIntervalSince1970),
            repliedMessageId: repliedMessage?.id,
            repliedMessageText: repliedMessage?.message,
            image: image, 
            isCurrentUser: true
        )
        intermediaryMessages.append(newMessage)
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
    
    private func postNewMessage(withTemporaryId tempId: String, chatId: String, text: String?, imageUrl: String?, repliedMessage: FormattedMessage?, token: String) async {
        let result = await AYServices.shared.postNewMessage(chatId: chatId, text: text, imageUrl: imageUrl, repliedMessageId: repliedMessage?.id, token: token)
        
        switch result {
        case .success:
            playSendMessageSound()
            updateMessage(withId: tempId, toStatus: .sent)
            await getMessages(chatId: chatId, token: token)
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
    
    private func playSendMessageSound() {
        guard let url = Bundle.main.url(forResource: "sent-message-sound", withExtension: "mp3") else { return }
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
        formattedMessages.removeAll { $0.id == messageId }
    }
    
//    func indexForMessage(withId messageId: String) -> Int? {
//        return formattedMessages.firstIndex { $0.id == messageId }
//    }
    
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
}
