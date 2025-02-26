//
//  PostCommunityMessageResonse.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 24/02/25.
//

import Foundation

struct PostCommunityMessageResonse: Codable {
    let _id: String
    let communityId: String
    let senderUserUid: String
    let text: String
    let createdAt: Int
}
