//
//  BusinessCategory.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 02/03/25.
//

import Foundation

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
    
    var iconName: String {
        switch self {
        case .eatAndDrink: return "fork.knife"
        case .partyAndEvent: return "sparkles"
        case .wellness: return "leaf"
        case .health: return "cross.case.fill"
        case .services: return "wrench.and.screwdriver"
        case .selling: return "cart.fill"
        case .techAndGames: return "gamecontroller.fill"
        case .pets: return "pawprint.fill"
        case .education: return "book.fill"
        case .adult: return "flame.fill"
        case .home: return "house.fill"
        }
    }
}
