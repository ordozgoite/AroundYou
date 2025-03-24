//
//  HomeSection.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 21/03/25.
//

import SwiftUI

enum HomeSection: String, CaseIterable {
    case places = "Places"
    case discover = "People"
    case communities = "Communities"
    case business = "Businesses"
    
    var iconName: String {
        return switch self {
        case .places:
            "building.2"
        case .discover:
            "heart"
        case .business:
            "storefront"
        case .communities:
            "person.3"
        }
    }
    
    var color: Color {
        return switch self {
        case .places:
                .blue
        case .discover:
                .pink
        case .business:
                .orange
        case .communities:
                .brown
        }
    }
}
