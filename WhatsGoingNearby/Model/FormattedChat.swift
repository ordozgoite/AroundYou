//
//  FormattedChat.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 28/03/24.
//

import Foundation

struct FormattedChat: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let chatName: String
    let otherUserUid: String
    let chatPic: String?
    let lastMessageAt: Int?
    let hasUnreadMessages: Bool
    let lastMessage: String?
    var isMuted: Bool
    var isLocked: Bool
    /// Rascunho não enviado desta conversa, preenchido pelo cliente a partir do cache local.
    ///
    /// Não vem do servidor, que não sabe da existência dele. É opcional também por isso: a
    /// decodificação da resposta da API simplesmente não encontra a chave e deixa `nil`.
    var draftText: String?
}
