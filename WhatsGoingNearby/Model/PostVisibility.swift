//
//  PostVisibility.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 15/02/24.
//

import Foundation
import SwiftUI

enum PostLocationVisibility: CaseIterable {
    case hidden
    case visible
    
    var title: LocalizedStringKey {
        switch self {
        case .visible:
            return "Show my location on map"
        case .hidden:
            return "Hide my location"
        }
    }
    
    var isLocationVisible: Bool {
        switch self {
        case .visible:
            return true
        case .hidden:
            return false
        }
    }
    
    var imageName: String {
        switch self {
        case .hidden:
            return "mappin.slash"
        case .visible:
            return "mappin"
        }
    }
}
