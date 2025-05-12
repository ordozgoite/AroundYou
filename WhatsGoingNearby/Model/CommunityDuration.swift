//
//  CommunityDuration.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 07/02/25.
//

import Foundation
import SwiftUI

enum CommunityDuration: Int, CaseIterable {
    case oneHour = 1
    case twoHours = 2
    case threeHours = 3
    case fourHours = 4
    
    var title: LocalizedStringKey {
        switch self {
        case .oneHour:
            return "1 hour"
        case .twoHours:
            return "2 hours"
        case .threeHours:
            return "3 hours"
        case .fourHours:
            return "4 hours"
        }
    }
    
    var abbreviatedTitle: String {
        switch self {
        case .oneHour:
            return "1 h"
        case .twoHours:
            return "2 h"
        case .threeHours:
            return "3 h"
        case .fourHours:
            return "4 h"
        }
    }
    
    var value: Int {
        switch self {
        case .oneHour:
            return 1
        case .twoHours:
            return 2
        case .threeHours:
            return 3
        case .fourHours:
            return 4
        }
    }
}
