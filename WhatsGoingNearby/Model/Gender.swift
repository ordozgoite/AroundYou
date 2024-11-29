//
//  Gender.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 22/11/24.
//

import Foundation
import SwiftUI

enum Gender: String, Codable, CaseIterable, Identifiable {
    case cisMale
    case transMale
    case cisFemale
    case transFemale
    
    var id: String { rawValue }
    
    var title: LocalizedStringKey {
        return switch self {
        case .cisMale:
            "Male"
        case .transMale:
            "Trans Male"
        case .cisFemale:
            "Female"
        case .transFemale:
            "Trans Female"
        }
    }
    
    var description: String {
        return switch self {
        case .cisMale:
            "cis-male"
        case .transMale:
            "trans-male"
        case .cisFemale:
            "cis-female"
        case .transFemale:
            "trans-female"
        }
    }
}

extension Gender {
    static func from(description: String) -> Gender? {
        return switch description {
        case "cis-male":
                .cisMale
        case "trans-male":
                .transMale
        case "cis-female":
                .cisFemale
        case "trans-female":
                .transFemale
        default:
            nil
        }
    }
    
    static func from(array: [String]) -> Set<Gender> {
        var genders: Set<Gender> = []
        for gender in array {
            if let gender = Gender.from(description: gender) {
                genders.insert(gender)
            }
        }
        return genders
    }
}
