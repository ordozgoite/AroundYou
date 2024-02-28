//
//  CommentDTO.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 28/02/24.
//

import Foundation

struct CommentDTO: Codable {
    let publicationId: String
    let text: String
    let repliedUserUid: String?
    let repliedUserName: String?
}
