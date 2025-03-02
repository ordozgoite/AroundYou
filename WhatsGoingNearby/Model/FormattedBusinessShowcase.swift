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

enum BusinessCategory: String, Codable, CaseIterable {
    case eatAndDrink
    case partyAndEvent
    case wellness
    case health
    case services
    case selling
    case techAndGames
    case pets
    case education
    case adult
    case home
    
    var title: String {
        return switch self {
        case .eatAndDrink: "Eat & Drink"
        case .partyAndEvent: "Party & Event"
        case .wellness: "Wellness"
        case .health: "Health"
        case .services:  "Services"
        case .selling: "Selling"
        case .techAndGames: "Tech & Games"
        case .pets: "Pets"
        case .education: "Education"
        case .adult: "Adult"
        case .home: "Home"
        }
    }
}


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
