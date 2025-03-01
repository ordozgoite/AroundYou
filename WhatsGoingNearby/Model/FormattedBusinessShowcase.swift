//
//  FormattedBusinessShowcase.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 26/02/25.
//

import Foundation

enum BusinessCategory: Codable {
    case food
    case service
    // TODO: completar com demais categorias
}

struct FormattedBusinessShowcase: Codable, Identifiable {
    let id: String
    let testImageName: String // ONLY FOR TESTS PURPOSE!
    let imageUrl: String?
    let title: String
    let description: String
//    let category: BusinessCategory
    let latitude: Double
    let longitude: Double
    let isLocationVisible: Bool
    let phoneNumber: String?
    let whatsAppNumber: String?
    let instagramUsername: String?
    let isPremium: Bool
}
