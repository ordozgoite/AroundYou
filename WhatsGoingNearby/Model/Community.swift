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
    var isMember: Bool
    var isPrivate: Bool
}
