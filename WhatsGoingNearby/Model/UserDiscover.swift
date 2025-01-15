//
//  UserDiscover.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 15/01/25.
//

import Foundation

struct UserDiscover: Codable {
    let userUid: String
    let username: String
    let profilePic: String?
    let locationLastUpdateAt: Int
    let gender: String
    let age: Int
}
