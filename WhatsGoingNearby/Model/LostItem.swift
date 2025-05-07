//
//  LostItem.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 09/04/25.
//

import Foundation

struct LostItem: Codable {
    let id: String
    let name: String
    let description: String?
    let imageUrl: String?
    let locationDescription: String?
    let latitude: Double
    let longitude: Double
    let lostDate: Int
    let hasReward: Bool
    var wasFound: Bool
    let userUid: String?
}
