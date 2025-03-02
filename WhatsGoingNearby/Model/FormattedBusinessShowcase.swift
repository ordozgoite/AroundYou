//
//  FormattedBusinessShowcase.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 26/02/25.
//

import Foundation

//Eat & Drink
//Party & Event
//Wellness
//Health
//Services
//Selling
//Tech & Games
//Pets
//Education
//Adult
//Home

struct FormattedBusinessShowcase: Codable, Identifiable {
    let id: String
    let testImageName: String // ONLY FOR TESTS PURPOSE!
    let imageUrl: String?
    let title: String
    let description: String
    let category: BusinessCategory
    let latitude: Double
    let longitude: Double
    let isLocationVisible: Bool
    let phoneNumber: String?
    let whatsAppNumber: String?
    let instagramUsername: String?
    let isPremium: Bool
}
