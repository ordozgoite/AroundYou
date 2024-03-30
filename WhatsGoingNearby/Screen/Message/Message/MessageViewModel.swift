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
    @Published var overlayError: (Bool, LocalizedStringKey) = (false, "")
    @Published var repliedMessage: FormattedMessage?
    
    func getMessages(chatId: String, token: String) async {
        let result = await AYServices.shared.getMessages(chatId: chatId, token: token)
        
        switch result {
        case .success(let messages):
            self.messages = messages
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
    }
    
    func sendMessage(chatId: String, text: String, repliedMessageId: String?, token: String) async {
        resetInputs()
        let result = await AYServices.shared.postNewMessage(chatId: chatId, text: text, repliedMessageId: repliedMessageId, token: token)
        
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
    
    private func resetInputs() {
        self.repliedMessage = nil
        self.messageText = ""
    }
    
    private func removeMessage(withId messageId: String) {
        messages.removeAll { $0.id == messageId }
    }
}
