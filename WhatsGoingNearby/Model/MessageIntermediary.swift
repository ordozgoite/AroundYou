//
//  MessageIntermediary.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 23/04/24.
//

import Foundation
import SwiftUI

struct MessageIntermediary {
    let id: String
    let chatId: String
    let text: String?
    let imageUrl: String?
    let isRead: Bool
    let createdAt: Int
    let repliedMessageId: String?
    let repliedMessageText: String?
    var status: MessageStatus?
    var image: UIImage?
    let isCurrentUser: Bool
    
    func formatMessage(isFirst: Bool, timeDivider: Int?) -> FormattedMessage {
        return FormattedMessage(
            id: self.id,
            chatId: self.chatId,
            message: self.text,
            imageUrl: self.imageUrl,
            isCurrentUser: self.isCurrentUser,
            isFirst: isFirst,
            repliedMessageText: self.repliedMessageText,
            repliedMessageId: self.repliedMessageId,
            timeDivider: timeDivider,
            image: self.image,
            status: self.status ?? .sent
        )
    }
}
