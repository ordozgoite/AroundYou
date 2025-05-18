//
//  HomeSection.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 21/03/25.
//

import SwiftUI

enum HomeSection: String, CaseIterable {
    case places
    case discover
    case communities
    case business
    
    var iconName: String {
        return switch self {
        case .places:
            "building.2"
        case .discover:
            "person.3"
        case .business:
            "storefront"
        case .communities:
            Constants.communityIconImageName
        }
    }
    
    var title: LocalizedStringKey {
        return switch self {
        case .places:
            "Places"
        case .discover:
            "People"
        case .communities:
            "Communities"
        case .business:
            "Businesses"
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
