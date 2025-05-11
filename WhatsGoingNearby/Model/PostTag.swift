//
//  PostTag.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 25/03/24.
//

import Foundation
import SwiftUI

enum PostTag: String, CaseIterable, Decodable {
    case help
    case hangout
    case chilling
    case news
    case party
    case bored
    
    var title: LocalizedStringKey {
        return switch self {
        case .help:
            "Some Help"
        case .hangout:
            "Some Company"
        case .chilling:
            "To Chill"
        case .news:
            "To Share Something"
        case .party:
            "To Party"
        case .bored:
            "To Kill Time"
        }
    }


//    var title: LocalizedStringKey {
//        return switch self {
//        case .help:
//            "Looking for help"
//        case .hangout:
//            "Looking for company"
//        case .chilling:
//            "Just chilling"
//        case .news:
//            "Sharing information"
//        case .party:
//            "Partying"
//        case .bored:
//            "Feeling bored"
//        }
//    }

    var iconName: String {
        return switch self {
        case .help:
            "hand.raised"
        case .hangout:
            "sparkles"
        case .chilling:
            "face.smiling"
        case .news:
            "megaphone"
        case .party:
            "party.popper"
        case .bored:
            "zzz"
        }
    }

    /*
     As cores das tags devem ser sempre cinza.
     Mas podemos, um dia, talvez por um curto período de tempo, adicionar uma tag especial com um design mais chamativo.
     */
    var color: Color {
        return .gray
    }
}
