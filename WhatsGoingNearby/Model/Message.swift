//
//  Message.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 28/03/24.
//

import Foundation

struct Message: Codable {
    let _id: String
    let chatId: String
    let senderUserUid: String
    let text: String?
    let imageUrl: String?
    let isRead: Bool
    let createdAt: Int
    let repliedMessageId: String?
    let repliedMessageText: String?
    
    func convertMessageToIntermediary(forCurrentUserUid userUid: String) -> MessageIntermediary {
        return MessageIntermediary(
            id: self._id,
            chatId: self.chatId,
            text: self.text,
            imageUrl: self.imageUrl,
            isRead: self.isRead,
            createdAt: self.createdAt,
            repliedMessageId: self.repliedMessageId,
            repliedMessageText: self.repliedMessageText, 
            isCurrentUser: userUid == self.senderUserUid
        )
    }
}
