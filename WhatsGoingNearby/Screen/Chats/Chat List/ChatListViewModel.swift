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

    private let chatStore: ChatStore

    init(chatStore: ChatStore = .shared) {
        self.chatStore = chatStore
        // O cache entra antes de qualquer requisição: a lista nasce preenchida em vez de
        // esperar a rede para ter o que desenhar.
        self.chats = chatStore.loadChats()
        self.isInitialChatsFetched = !self.chats.isEmpty
        refreshDrafts()
    }

    //MARK: - Rascunhos

    /// Reaplica os rascunhos sobre a lista já em tela.
    ///
    /// Chamado quando a lista reaparece, porque a conversa que acabou de ser fechada pode ter
    /// deixado — ou consumido — um rascunho, e essa mudança não passa por nenhuma requisição.
    func refreshDrafts() {
        let updated = applyingDrafts(to: chats)
        guard updated != chats else { return }
        chats = updated
    }

    /// Decora as conversas com o rascunho de cada uma.
    ///
    /// A ordem não muda: a lista continua ordenada pela última mensagem, que é do servidor.
    /// Deixar um rascunho reordenar a conversa criaria uma ordenação local disputando com a
    /// que vem da API a cada sincronização.
    private func applyingDrafts(to chats: [FormattedChat]) -> [FormattedChat] {
        let drafts = chatStore.loadDrafts()
        guard !drafts.isEmpty else {
            return chats.map { chat in
                var chat = chat
                chat.draftText = nil
                return chat
            }
        }

        return chats.map { chat in
            var chat = chat
            chat.draftText = drafts[chat.id]?.text
            return chat
        }
    }

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
        // Com dados em cache o spinner não aparece: a lista já está na tela e a atualização
        // acontece por baixo, sem piscar.
        if !isInitialChatsFetched { isLoading = true }
        let result = await AYServices.shared.getChatsByUser(token: token)
        if !isInitialChatsFetched { isLoading = false }

        switch result {
        case .success(let chats):
            // Reconcilia por id — insere, atualiza e remove o que sumiu do servidor. Não é
            // apagar tudo e reinserir, que descartaria as mensagens já persistidas.
            chatStore.reconcile(with: chats)
            // Só reatribui se algo mudou de fato: substituir por uma lista igual faria a
            // List refazer as linhas à toa a cada evento de socket.
            let decorated = applyingDrafts(to: chats)
            if self.chats != decorated {
                self.chats = decorated
            }
            isInitialChatsFetched = true
        case .failure:
            overlayError = (true, ErrorMessage.getChats)
        }
    }

    func deleteChat(chatId: String, token: String) async {
        let result = await AYServices.shared.deleteChat(chatId: chatId, token: token)
        
        switch result {
        case .success:
            chatStore.delete(chatId: chatId)
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
        let isMuted = newStatus == .mute
        if let index = chats.firstIndex(where: { $0.id == chatId }) {
            chats[index].isMuted = isMuted
        }
        chatStore.update(chatId: chatId, isMuted: isMuted)
    }
}
