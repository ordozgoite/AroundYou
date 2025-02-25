//
//  CommunityMessage.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 24/02/25.
//

import Foundation

struct CommunityMessage: Codable {
    let _id: String
    let communityId: String
    let senderUserUid: String
    let senderUsername: String?
    let senderProfilePic: String?
    let text: String
    let createdAt: Int
    let repliedMessageId: String?
    let repliedMessageText: String?
    
    func convertMessageToIntermediary(forCurrentUserUid userUid: String) -> CommunityMessageIntermediary {
        return CommunityMessageIntermediary(
            id: self._id,
            communityId: self.communityId,
            text: self.text,
            createdAt: self.createdAt,
            isCurrentUser: userUid == self.senderUserUid,
            senderUserUid: self.senderUserUid,
            senderUsername: self.senderUsername ?? "",
            senderProfilePic: self.senderProfilePic
        )
    }
}
