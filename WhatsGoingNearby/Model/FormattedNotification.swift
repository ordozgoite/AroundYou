//
//  FormattedNotification.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 29/02/24.
//

import Foundation
import SwiftUI

enum NotificationAction: Codable {
    case like
    case comment
    
    var text: String {
        switch self {
        case .like:
            return "liked"
        case .comment:
            return "commented"
        }
    }
}

enum ActionTarget: Codable {
    case publication
    case comment
    
    var text: String {
        switch self {
        case .publication:
            return "publication"
        case .comment:
            return "comment"
        }
    }
}

struct FormattedNotification: Identifiable, Codable {
    let id: String
    let sendingUserName: String
    let sendingUserProfilePic: String?
    let action: NotificationAction
    let target: ActionTarget
    let targetId: String
}
