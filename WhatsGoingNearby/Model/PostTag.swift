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
    case eat
    case buy
    
    var title: LocalizedStringKey {
        return switch self {
        case .help:
             "Looking for help"
        case .info:
            "Asking for information"
        case .chat:
            "Chatting"
        case .hangout:
            "Seeking Hangout"
        case .news:
            "Sharing news"
        case .chilling:
            "Just chilling"
        case .eat:
            "Wanna eat"
        case .buy:
            "Wanna buy"
        }
    }
    
    var iconName: String {
        return switch self {
        case .help:
            "hand.raised"
        case .info:
            "questionmark.bubble"
        case .chat:
            "bubble.left.and.bubble.right"
        case .hangout:
            "party.popper"
        case .news:
            "megaphone"
        case .chilling:
            "face.smiling"
        case .eat:
            "fork.knife"
        case .buy:
            "cart"
        }
    }
    
    var color: Color {
        return switch self {
        case .help:
                .red
        default:
                .gray
        }
    }
}
