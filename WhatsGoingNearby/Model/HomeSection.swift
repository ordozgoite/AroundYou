//
//  HomeSection.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 21/03/25.
//

import SwiftUI

enum HomeSection: String, CaseIterable {
    case posts = "Posts"
    case discover = "People"
    case business = "Businesses"
    case urgent = "Urgent"
    case communities = "Communities"
    
    var iconName: String {
        return switch self {
        case .posts:
            "quote.bubble"
        case .discover:
            "heart"
        case .business:
            "storefront"
        case .urgent:
            "light.beacon.max"
        case .communities:
            "person.3"
        }
    }
    
    var color: Color {
        return switch self {
        case .posts:
                .blue
        case .discover:
                .pink
        case .business:
                .orange
        case .urgent:
                .red
        case .communities:
                .brown
        }
    }
}
