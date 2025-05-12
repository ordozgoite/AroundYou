//
//  UserDiscoverPreferences.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 27/10/24.
//

import Foundation

struct UserDiscoverPreferences: Codable {
    let isDiscoverEnabled: Bool
    let age: Int
    let gender: String
    let interestGender: [String]
    let minInterestAge: Int
    let maxInterestAge: Int
}
