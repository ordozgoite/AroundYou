//
//  MessageViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 28/03/24.
//

import Foundation
import SwiftUI

@MainActor
class MessageViewModel: ObservableObject {
    
    @Published var messages: [FormattedMessage] = []
    @Published var messageText: String = ""
    @Published var isLoading: Bool = false
    @Published var overlayError: (Bool, LocalizedStringKey) = (false, "")
    @Published var scrollToBottom: Bool = false
    
    func getMessages(chatId: String, token: String) async {
        isLoading = true
        let result = await AYServices.shared.getMessages(chatId: chatId, token: token)
        isLoading = false
        
        switch result {
        case .success(let messages):
            self.messages = messages
            goToLastMessage()
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
    }
    
    func sendMessage(chatId: String, text: String, token: String) async {
        resetTextField()
        let result = await AYServices.shared.postNewMessage(chatId: chatId, text: text, token: token)
        
        switch result {
        case .success(let message):
            addFormattedMessage(with: message)
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
    }
    
    private func resetTextField() {
        self.messageText = ""
    }
    
    private func addFormattedMessage(with message: Message) {
        let newMessage = FormattedMessage(id: message._id, message: message.text, isCurrentUser: true, isFirst: true) // fix "isFirst"
        messages.append(newMessage)
        goToLastMessage()
    }
    
    private func goToLastMessage() {
        self.scrollToBottom = true
    }
}
