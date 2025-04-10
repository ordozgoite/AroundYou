//
//  IncidentType.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 09/04/25.
//

import SwiftUI

enum IncidentType: String, Codable, CaseIterable {
    case human
    case animal
    case property
    
    var title: LocalizedStringKey {
        return switch self {
        case .human:
            "Harm to a Person"
        case .animal:
            "Animal Abuse"
        case .property:
            "Property Damage"
        }
    }
    
    var iconName: String {
        return switch self {
        case .human:
            "figure.stand"
        case .animal:
            "dog"
        case .property:
            "house.fill"
        }
    }
}
