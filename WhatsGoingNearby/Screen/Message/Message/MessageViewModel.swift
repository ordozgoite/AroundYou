//
//  MessageViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 28/03/24.
//

import Foundation

@MainActor
class MessageViewModel: ObservableObject {
    
    @Published var messages: [FormattedMessage] = [
        FormattedMessage(message: "Boa noite, tio! Já terminou de fazer aquela parte das mensagens?", isCurrentUser: false, isFirst: true),
        FormattedMessage(message: "Porra! Tu pensa que é rapido, é?", isCurrentUser: true, isFirst: false),
        FormattedMessage(message: "Já estou trabalhando nessa funcionalidade, mano. Fique tranquilo 😉", isCurrentUser: true, isFirst: true)
    ]
    @Published var messageText: String = ""
    
    func sendMessage() {
        let newMessage = FormattedMessage(message: messageText, isCurrentUser: true, isFirst: true)
        messages.append(newMessage)
        messageText = ""
    }
}
