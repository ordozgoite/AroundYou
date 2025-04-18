//
//  PostData.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 14/02/24.
//

import Foundation

struct FormattedPost: Identifiable, Codable {
    let id: String
    let userUid: String
    let userProfilePic: String?
    let username: String
    let timestamp: Int
    let expirationDate: Int
    let text: String?
    var likes: Int?
    var didLike: Bool?
    var comment: Int?
    let latitude: Double?
    let longitude: Double?
    let distanceToMe: Double?
    let isFromRecipientUser: Bool
    let isLocationVisible: Bool?
    let tag: String?
    let imageUrl: String?
    let isOwnerFarAway: Bool?
    var isFinished: Bool?
    let duration: Int?
    var isSubscribed: Bool?
    let source: String
    var description: String?
    var name: String?
    
    var postDuration: PostDuration {
        switch duration {
        case 1:
            return .oneHour
        case 2:
            return .twoHours
        case 3:
            return .threeHours
        case 4:
            return .fourHours
        default:
            return .fourHours
        }
    }
    var postTag: PostTag? {
        return switch tag {
        case "chat":
                .chat
        case "help":
                .help
        case "info":
                .info
        case "hangout":
                .hangout
        case "news":
                .news
        case "chilling":
                .chilling
        case "buy":
                .buy
        case "eat":
                .eat
        case "work":
                .work
        default:
            nil
        }
    }
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
    
    var isOld: Bool {
        return expirationDate.timeIntervalSince1970InSeconds < getCurrentDateTimestamp()
    }
    
    var status: PostStatus {
        return isOld || isOwnerFarAway ?? false || isFinished ?? false ? .expired : .active
    }

    
    var postSource: PostSource {
        return switch source {
        case "report":
                .report
        case "lostItem":
                .lostItem
        default:
                .publication
        }
    }
}
