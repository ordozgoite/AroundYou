//
//  FormattedCommunity.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 08/02/25.
//

import Foundation

struct FormattedCommunity: Codable, Identifiable {
    let id: String
    var name: String
    var imageUrl: String?
    var description: String?
    let createdAt: Int
    let expirationDate: Int
    var isMember: Bool
    var askedToJoin: Bool?
    let isOwner: Bool
    var isPrivate: Bool
    let isLocationVisible: Bool
    let latitude: Double?
    let longitude: Double?
    
    var isActive: Bool {
        return expirationDate.timeIntervalSince1970InSeconds >= getCurrentDateTimestamp()
    }
}
