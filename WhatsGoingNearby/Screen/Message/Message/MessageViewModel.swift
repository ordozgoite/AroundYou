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

@MainActor
class MessageViewModel: ObservableObject {
    
    var socket = SocketService.shared.getSocket()
    @Published var formattedMessages: [FormattedMessage] = []
    @Published var messages: [Message] = [] {
        didSet {
            self.formattedMessages = formatMessages()
        }
    }
    @Published var messageText: String = ""
    @Published var overlayError: (Bool, LocalizedStringKey) = (false, "")
    @Published var repliedMessage: FormattedMessage?
    @Published var messageTimer: Timer?
    @Published var highlightedMessageId: String?
    
    @Published var image: UIImage?
    @Published var isCameraDisplayed = false
    @Published var isPhotosDisplayed = false
    
    func getMessages(chatId: String, token: String) async {
        let result = await AYServices.shared.getMessages(chatId: chatId, token: token)
        
        switch result {
        case .success(let messages):
            self.messages = messages
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
    }
    
    private func formatMessages() -> [FormattedMessage] {
        guard !messages.isEmpty else {
            return []
        }
        
        var formattedMessages: [FormattedMessage] = []
        
        for (index, message) in messages.enumerated() {
            let formattedMessage = message.formatMessage(isCurrentUser: isMyMessage(message), isFirst: getTail(forMessage: message, withIndex: index), timeDivider: getTimeDivider(forMessage: message, withIndex: index))
            formattedMessages.append(formattedMessage)
        }
        
        return formattedMessages
    }
    
    private func isMyMessage(_ message: Message) -> Bool {
        return message.senderUserUid == LocalState.currentUserUid
    }
    
    private func getTail(forMessage message: Message, withIndex index: Int) -> Bool {
        guard index < messages.count - 1 else {
            return true
        }
        
        let nextMessage = messages[index + 1]
        let timeDifferenceSec = nextMessage.createdAt.timeIntervalSince1970InSeconds - message.createdAt.timeIntervalSince1970InSeconds
        return timeDifferenceSec >= 60
    }
    
    private func getTimeDivider(forMessage message: Message, withIndex index: Int) -> Int? {
        guard index > 0 else {
            return message.createdAt
        }
        
        let previousMessage = messages[index - 1]
        let timeDifferenceSec = message.createdAt.timeIntervalSince1970InSeconds - previousMessage.createdAt.timeIntervalSince1970InSeconds
        return timeDifferenceSec >= 3600 ? message.createdAt : nil
    }
    
    func sendMessage(chatId: String, text: String?, image: UIImage?, repliedMessageId: String?, token: String) async {
        resetInputs()
        
        var imageURL: String? = nil
        if let img = image {
            do {
                imageURL = try await storeImage(img)
            } catch {
                overlayError = (true, ErrorMessage.defaultErrorMessage)
                return
            }
        }
        
        let result = await AYServices.shared.postNewMessage(chatId: chatId, text: text, imageUrl: imageURL, repliedMessageId: repliedMessageId, token: token)
        
        switch result {
        case .success:
            await getMessages(chatId: chatId, token: token)
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
    }
    
    func deleteMessage(messageId: String, token: String) async {
        let result = await AYServices.shared.deleteMessage(messageId: messageId, token: token)
        
        switch result {
        case .success:
            removeMessage(withId: messageId)
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
    }
    
    private func storeImage(_ image: UIImage) async throws -> String? {
        let storageRef = Storage.storage().reference()
        let fileRef = storageRef.child("post-image/\(UUID().uuidString).jpg")
        let imageData = image.jpegData(compressionQuality: 0.8)
        _ = try await fileRef.putDataAsync(imageData!)
        let imageUrl = try await fileRef.downloadURL()
        return imageUrl.absoluteString
    }
    
    private func resetInputs() {
        self.repliedMessage = nil
        self.messageText = ""
        self.image = nil
    }
    
    private func removeMessage(withId messageId: String) {
        formattedMessages.removeAll { $0.id == messageId }
    }
    
    func indexForMessage(withId messageId: String) -> Int? {
        return formattedMessages.firstIndex { $0.id == messageId }
    }
}
