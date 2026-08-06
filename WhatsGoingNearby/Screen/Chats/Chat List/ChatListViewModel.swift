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
    @Published var isInitialChatsFetched: Bool = false

    private var isFetchingChats = false
    private var hasPendingChatsFetch = false

    /// Atualiza a lista coalescendo os gatilhos.
    ///
    /// Vários eventos podem pedir a atualização quase ao mesmo tempo (mensagem nova,
    /// evento de chat, reconexão). Em vez de uma requisição por evento, mantemos no máximo
    /// uma em voo e uma reexecução, o que também garante que o último evento não seja
    /// atendido por uma resposta antiga.
    func getChats(token: String) async {
        guard !isFetchingChats else {
            hasPendingChatsFetch = true
            return
        }

        isFetchingChats = true
        defer { isFetchingChats = false }

        await fetchChats(token: token)

        if hasPendingChatsFetch {
            hasPendingChatsFetch = false
            await fetchChats(token: token)
        }
    }

    private func fetchChats(token: String) async {
        if !isInitialChatsFetched { isLoading = true }
        let result = await AYServices.shared.getChatsByUser(token: token)
        if !isInitialChatsFetched { isLoading = false }

        switch result {
        case .success(let chats):
            self.chats = chats
            isInitialChatsFetched = true
        case .failure:
            overlayError = (true, ErrorMessage.getChats)
        }
    }

    func deleteChat(chatId: String, token: String) async {
        let result = await AYServices.shared.deleteChat(chatId: chatId, token: token)
        
        switch result {
        case .success:
            await getChats(token: token)
        case .failure:
            overlayError = (true, ErrorMessage.deleteChat)
        }
    }
    
    func muteChat(chatId: String, token: String) async {
        let result = await AYServices.shared.muteChat(chatId: chatId, token: token)
        
        switch result {
        case .success:
            updateChat(withId: chatId, to: .mute)
        case .failure:
            overlayError = (true, ErrorMessage.muteChat)
        }
    }
    
    func unmuteChat(chatId: String, token: String) async {
        let result = await AYServices.shared.unmuteChat(chatId: chatId, token: token)
        
        switch result {
        case .success:
            updateChat(withId: chatId, to: .unmute)
        case .failure:
            overlayError = (true, ErrorMessage.unmuteChat)
        }
    }
    
    private func updateChat(withId chatId: String, to newStatus: ChatMuteStatus) {
        if let index = chats.firstIndex(where: { $0.id == chatId }) {
            chats[index].isMuted = newStatus == .mute
        }
    }
}
