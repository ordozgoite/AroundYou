//
//  FormattedCommunityMessage.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 24/02/25.
//

import Foundation
import SwiftUI

struct FormattedCommunityMessage: Identifiable, Equatable, Hashable {
    let id: String
    let communityId: String
    var text: String
    var isCurrentUser: Bool
    var isFirst: Bool
    var repliedMessageText: String?
    var repliedMessageId: String?
    var timeDivider: Int?
    var status: MessageStatus
    var createdAt: Int
    var senderUsername: String
    var senderProfilePic: String?
    var userDivider: Bool
}
