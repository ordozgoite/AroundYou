//
//  EditBiographyResponse.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 16/02/24.
//

import Foundation

struct EditProfileResponse: Codable {
    let username: String
    let name: String?
    let biography: String?
    let profilePic: String?
}
