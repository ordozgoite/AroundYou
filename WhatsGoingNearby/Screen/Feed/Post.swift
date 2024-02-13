//
//  Post.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import Foundation

struct Post: Identifiable {
    let id = UUID()
    let userUid: String
    let text: String
    let timestamp: Date
    let latitude: String
    let longitude: String
}
