//
//  PostNewUserResponse.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 14/02/24.
//

import Foundation

struct MongoUser: Codable {
    let userUid: String
    let username: String
    let name: String?
    let profilePic: String?
    let biography: String?
}
