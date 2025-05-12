//
//  Chat.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 28/03/24.
//

import Foundation

struct Chat: Codable {
    let _id: String
    let mutedUserUids: [String]
    let participantUserUids: [String]
    let createdAt: String
    var isLocked: Bool
}
