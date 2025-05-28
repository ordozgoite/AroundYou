//
//  Community.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 03/02/25.
//

import Foundation

struct Community: Codable, Identifiable {
    let id: String
    let name: String
    let imageUrl: String?
    let description: String?
    let latitude: Double
    let longitude: Double
    let isLocationVisible: Bool
//    let duration: Int
//    let createdAt: Date
//    let expirationDate: Date
    
    enum CodingKeys: String, CodingKey, Decodable {
        case id = "_id"
        case name
        case imageUrl
        case description
        case latitude
        case longitude
        case isLocationVisible
//        case duration
//        case createdAt
//        case expirationDate
    }
}
