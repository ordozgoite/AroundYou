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
    @Published var messages: [FormattedMessage] = []
    @Published var messageText: String = ""
    @Published var overlayError: (Bool, LocalizedStringKey) = (false, "")
    @Published var repliedMessage: FormattedMessage?
    @Published var messageTimer: Timer?
    
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
        messages.removeAll { $0.id == messageId }
    }
    
    func indexForMessage(withId messageId: String) -> Int? {
        return messages.firstIndex { $0.id == messageId }
    }
}
