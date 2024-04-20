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
    
    
    func formatMessage(isCurrentUser: Bool, isFirst: Bool, timeDivider: Int?) -> FormattedMessage {
        return FormattedMessage(id: self._id, message: self.text, imageUrl: self.imageUrl, isCurrentUser: isCurrentUser, isFirst: isFirst, repliedMessageText: repliedMessageText, repliedMessageId: repliedMessageId, timeDivider: timeDivider)
    }
}
