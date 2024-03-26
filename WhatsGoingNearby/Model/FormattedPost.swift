//
//  PostData.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 14/02/24.
//

import Foundation

// Post Info:
// User profile pic
// User name
// Post timestamp
// Post text
// Post comments number
// Post likes number

struct FormattedPost: Identifiable, Codable {
    let id: String
    let userUid: String
    let userProfilePic: String?
    let username: String
    let timestamp: Int
    let expirationDate: Int
    let text: String
    var likes: Int
    var didLike: Bool
    var comment: Int
    let latitude: Double?
    let longitude: Double?
    let distanceToMe: Double?
    let isFromRecipientUser: Bool
    let isLocationVisible: Bool
    let tag: String?
    var postTag: PostTag? {
        switch tag {
        case "chat":
            return .chat
        case "help":
            return .help
        case "info":
            return .info
        case "hangout":
            return .hangout
        case "news":
            return .news
        case "chilling":
            return .chilling
        default:
            return nil
        }
    }
    var isSubscribed: Bool
    var date: Date {
        return NSDate(timeIntervalSince1970: TimeInterval(self.timestamp.timeIntervalSince1970InSeconds)) as Date
    }
    var formattedDistanceToMe: String? {
        if let distance = distanceToMe {
            if distance > 1000 {
                return String(Int(distance) / 1000) + "km"
            } else {
                return String(Int(distance)) + "m"
            }
        } else {
            return nil
        }
    }
    
    var type: PostType {
        if expirationDate.timeIntervalSince1970InSeconds > getCurrentDateTimestamp() {
            return .active
        } else {
            return .inactive
        }
    }
}
