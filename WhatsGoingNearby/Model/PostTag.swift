//
//  PostTag.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 25/03/24.
//

import Foundation
import SwiftUI

enum PostTag: CaseIterable {
    case chat
    case help
    case info
    case company
    case news
    case chilling
    
    var title: LocalizedStringKey {
        switch self {
        case .help:
            return "Looking for help"
        case .info:
            return "Asking for information"
        case .chat:
            return "Chatting"
        case .company:
            return "Seeking Hangout"
        case .news:
            return "Sharing news"
        case .chilling:
            return "Just chilling"
        }
    }
    
    var iconName: String {
        switch self {
        case .help:
            return "figure.wave.circle"
        case .info:
            return "questionmark.bubble"
        case .chat:
            return "bubble.left.and.bubble.right"
        case .company:
            return "party.popper"
        case .news:
            return "newspaper"
        case .chilling:
            return "face.smiling"
        }
    }
}
