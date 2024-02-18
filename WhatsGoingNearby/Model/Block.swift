//
//  Block.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 18/02/24.
//

import Foundation

struct Block: Codable {
    let blockedUserUid: String
    let blockingUserUid: String
    let blockDateTime: String
}
