//
//  ChatMessageNotification.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 29/05/25.
//

import Foundation

struct ChatMessageNotification: Codable {
    let senderUsername: String
    let messageText: String?
    let senderProfilePicUrl: String?
    let chat: FormattedChat
}
