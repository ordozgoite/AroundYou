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
    
//    enum CodingKeys: String, CodingKey, Decodable {
//        case id = "_id"
//        case imageUrl
//        case title
//        case description
//        case category
//        case latitude
//        case longitude
//        case isLocationVisible
//        case phoneNumber
//        case whatsAppNumber
//        case instagramUsername
//        case isOwner
//        case distance
//        case ownerUid
//    }
}
