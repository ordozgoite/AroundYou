//
//  CommunityMessageIntermediary.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 24/02/25.
//

import Foundation

struct CommunityMessageIntermediary {
    var id: String
    var communityId: String
    var text: String
    var createdAt: Int
    var repliedMessageId: String?
    var repliedMessageText: String?
    var status: MessageStatus?
    var isCurrentUser: Bool
    var senderUserUid: String
    var senderUsername: String
    var senderProfilePic: String?
    
    func formatMessage(isFirst: Bool, timeDivider: Int?, userDivider: Bool) -> FormattedCommunityMessage {
        return FormattedCommunityMessage(
            id: self.id,
            communityId: self.communityId,
            text: self.text,
            isCurrentUser: self.isCurrentUser,
            isFirst: isFirst,
            timeDivider: timeDivider,
            status: self.status ?? .sent,
            createdAt: self.createdAt,
            senderUsername: self.senderUsername,
            senderProfilePic: self.senderProfilePic,
            userDivider: userDivider
        )
    }
}
