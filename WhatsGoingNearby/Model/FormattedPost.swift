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
    let userName: String
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
    var date: Date {
        return NSDate(timeIntervalSince1970: TimeInterval(self.timestamp.timeIntervalSince1970InSeconds)) as Date
    }
    var formattedDistanceToMe: String? {
        if let distance = distanceToMe {
            return String(Int(distance))
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
