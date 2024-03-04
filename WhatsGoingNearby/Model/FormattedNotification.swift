//
//  FormattedNotification.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 29/02/24.
//

import Foundation
import SwiftUI

enum NotificationAction: String, Codable {
    case like
    case comment
    case reply
    
    var text: String {
        switch self {
        case .like:
            return "liked"
        case .comment:
            return "commented"
        case .reply:
            return "replied"
        }
    }
}

enum ActionTarget: String, Codable {
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
    let sendingUserUid: String
    let sendingUsername: String
    let sendingUserProfilePic: String?
    let action: NotificationAction
    let target: ActionTarget
    let publicationId: String
    let notificationDateTime: Int
    var date: Date {
        return NSDate(timeIntervalSince1970: TimeInterval(self.notificationDateTime.timeIntervalSince1970InSeconds)) as Date
    }
}
