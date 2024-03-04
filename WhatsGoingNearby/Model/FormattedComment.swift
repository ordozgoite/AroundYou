//
//  FormattedComment.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 14/02/24.
//

import Foundation

struct FormattedComment: Codable, Identifiable {
    let id: String
    let userUid: String
    let publicationId: String
    let text: String
    let timestamp: Int
    let userProfilePic: String?
    let username: String
    let isFromRecipientUser: Bool
    var didLike: Bool
    var likes: Int
    let repliedUserUsername: String?
    let repliedUserUid: String?
    var date: Date {
        return NSDate(timeIntervalSince1970: TimeInterval(self.timestamp.timeIntervalSince1970InSeconds)) as Date
    }
}
