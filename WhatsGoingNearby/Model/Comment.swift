//
//  Comment.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 14/02/24.
//

import Foundation

struct Comment: Codable {
    let id: String
    let userUid: String
    let publicationId: String
    let text: String
    let timestamp: Int
    
    enum CodingKeys: String, CodingKey, Decodable {
        case id = "_id"
        case userUid
        case publicationId
        case text
        case timestamp
    }
}
