//
//  FormattedChat.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 28/03/24.
//

import Foundation

struct FormattedChat: Codable, Identifiable, Equatable {
    let id: String
    let chatName: String
    let otherUserUid: String
    let chatPic: String?
    let lastMessageAt: Int?
    let hasUnreadMessages: Bool
    let lastMessage: String?
    var isMuted: Bool
    var isLocked: Bool
}
