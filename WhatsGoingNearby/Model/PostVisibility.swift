//
//  PostVisibility.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 15/02/24.
//

import Foundation

enum PostVisibility: CaseIterable {
    case identified
    case anonymous
    
    var title: String {
        switch self {
        case .identified:
            return "Identified"
        case .anonymous:
            return "Anonymous"
        }
    }
}
