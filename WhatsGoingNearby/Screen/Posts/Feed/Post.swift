//
//  Post.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import Foundation

struct Post: Identifiable, Codable {
    let id: String
    let userUid: String
    let text: String
    let timestamp: String
    let latitude: Double
    let longitude: Double
    
    enum CodingKeys: String, CodingKey, Decodable {
        case id = "_id"
        case userUid
        case text
        case timestamp
        case latitude
        case longitude
    }
}
