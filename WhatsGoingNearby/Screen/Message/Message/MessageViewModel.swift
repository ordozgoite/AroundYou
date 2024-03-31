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
    
    var socket = SocketService.shared.getSocket()
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
            
            sendMessage(text: text, room: chatId)
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
    
    //MARK: - Web Socket
    
    func decodeMessages(message: [Any]) {
        print("⚠️⚠️⚠️")
        print(message)
        print("⚠️⚠️⚠️")
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: message[0], options: [])
            
            let newMessage = try JSONDecoder().decode(Message.self, from: jsonData)
            
            // append message to array
        } catch {
            print(error)
        }
    }
    
    private func sendMessage(text: String, room: String) {
        socket.emit("message", [text, room])
    }
}
