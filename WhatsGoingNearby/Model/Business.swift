//
//  Business.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 11/03/25.
//

import Foundation

struct Business: Codable {
    let title: String
    let description: String?
    let imageUrl: String?
    let category: String
    let latitude: String
    let longitude: String
    let isLocationVisible: Bool
    let phoneNumber: String?
    let whatsAppNumber: String?
    let instagramUsername: String?
}
