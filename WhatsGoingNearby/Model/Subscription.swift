//
//  Subscription.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 01/03/24.
//

import Foundation

enum SubsctiptionState: String, Codable {
    case subscribed
    case unsubscribed
}

struct Subscription: Codable {
    
    let _id: String
    let userUid: String
    let publicationId: String
    let subscriptionState: SubsctiptionState
    let subscriptionDateTime: String
}
