//
//  ChatListViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 28/03/24.
//

import Foundation
import SwiftUI

enum ChatMuteStatus {
    case mute
    case unmute
}

@MainActor
class ChatListViewModel: ObservableObject {
    
    @Published var chats: [FormattedChat] = []
    @Published var isLoading: Bool = false
    @Published var overlayError: (Bool, LocalizedStringKey) = (false, "")
    
    func getChats(token: String) async {
        isLoading = true
        let result = await AYServices.shared.getChatsByUser(token: token)
        isLoading = false
        
        switch result {
        case .success(let chats):
            self.chats = chats
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
    }
    
    func muteChat(chatId: String, token: String) async {
        let result = await AYServices.shared.muteChat(chatId: chatId, token: token)
        
        switch result {
        case .success:
            updateChat(withId: chatId, to: .mute)
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
    }
    
    func unmuteChat(chatId: String, token: String) async {
        let result = await AYServices.shared.unmuteChat(chatId: chatId, token: token)
        
        switch result {
        case .success:
            updateChat(withId: chatId, to: .unmute)
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
    }
    
    private func updateChat(withId chatId: String, to newStatus: ChatMuteStatus) {
        if let index = chats.firstIndex(where: { $0.id == chatId }) {
            chats[index].isMuted = newStatus == .mute
        }
    }
}
