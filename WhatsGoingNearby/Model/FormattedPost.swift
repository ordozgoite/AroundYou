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
    let userName: String?
    let timestamp: Date
    let text: String
//    let commentsNumber: Int
//    let likesNumber: Int
}
