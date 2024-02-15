//
//  PostNewCommentResponse.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 15/02/24.
//

import Foundation

struct PostNewCommentResponse: Codable {
    let id: String
    let userUid: String
    let publicationId: String
    let text: String
    let timestamp: String
    
    enum CodingKeys: String, CodingKey, Decodable {
        case id = "_id"
        case userUid
        case publicationId
        case text
        case timestamp
    }
}
