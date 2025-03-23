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
    case communities = "Communities"
    case business = "Businesses"
    case lostAndFound = "Lost and Found"
    case report = "Reports"
    case urgent = "Urgent"
    
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
        case .lostAndFound:
            "magnifyingglass"
        case .report:
            "megaphone"
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
        case .lostAndFound:
                .teal
        case .report:
                .orange
        }
    }
}
