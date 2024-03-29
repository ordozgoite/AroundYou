//
//  Chat.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 28/03/24.
//

import Foundation

struct Chat: Codable {
    let _id: String
    let mutedUserUid: [String]
    let participantUserUids: [String]
    let createdAt: Date
}
