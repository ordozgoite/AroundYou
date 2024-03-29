//
//  Message.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 28/03/24.
//

import Foundation

struct Message: Codable {
    let _id: String
    let chatId: String
    let senderUserUid: String
    let text: String
    let isRead: Bool
    let createdAt: String
}
