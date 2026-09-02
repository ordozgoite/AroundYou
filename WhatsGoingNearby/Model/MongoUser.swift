//
//  PostNewUserResponse.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 14/02/24.
//

import Foundation

enum UserRole: String, Codable {
    case user
    case admin
    case superadmin
}

struct MongoUser: Codable, Hashable {
    let userUid: String
    let username: String
    let name: String?
    let profilePic: String?
    let biography: String?
    var showProfileInPublicationViews: Bool? = nil
    // Texto, e não `UserRole`: um papel novo na API não pode fazer a decodificação do usuário falhar.
    var role: String? = nil
}
