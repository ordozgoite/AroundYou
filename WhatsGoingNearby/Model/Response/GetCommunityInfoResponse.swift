//
//  GetCommunityInfoResponse.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 19/02/25.
//

import Foundation

struct GetCommunityInfoResponse: Codable {
    var members: [MongoUser]
    var joinRequests: [MongoUser]?
    let ownerUid: String
}
