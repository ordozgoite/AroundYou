//
//  FormattedBusinessShowcase.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 26/02/25.
//

import Foundation

struct FormattedBusinessShowcase: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let imageUrl: String?
    let title: String
    let description: String?
    let category: BusinessCategory
    let latitude: Double
    let longitude: Double
    let isLocationVisible: Bool
    let phoneNumber: String?
    let whatsAppNumber: String?
    let instagramUsername: String?
    let isOwner: Bool
    let distance: Int
    let ownerUid: String
    let expirationDate: Int
    
    var isExpired: Bool {
        return self.expirationDate.timeIntervalSince1970InSeconds < getCurrentDateTimestamp()
    }
}
