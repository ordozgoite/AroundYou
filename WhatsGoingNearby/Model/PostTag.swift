//
//  PostTag.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 25/03/24.
//

import Foundation
import SwiftUI

enum PostTag: String, CaseIterable, Decodable {
    case chat
    case help
    case info
    case hangout
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
        case .hangout:
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
            return "hand.raised"
        case .info:
            return "questionmark.bubble"
        case .chat:
            return "bubble.left.and.bubble.right"
        case .hangout:
            return "party.popper"
        case .news:
            return "megaphone"
        case .chilling:
            return "face.smiling"
        }
    }
}
