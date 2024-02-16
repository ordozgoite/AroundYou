//
//  UserProfile.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 15/02/24.
//

import Foundation

struct UserProfile: Codable {
    let userUid: String
    let name: String
    let profilePic: String?
    let biography: String?
    let likes: Int
}