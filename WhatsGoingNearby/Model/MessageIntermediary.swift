//
//  MessageIntermediary.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 23/04/24.
//

import Foundation
import SwiftUI

struct MessageIntermediary {
    var id: String
    var chatId: String
    var text: String?
    var imageUrl: String?
    var isRead: Bool
    var createdAt: Int
    var repliedMessageId: String?
    var repliedMessageText: String?
    var status: MessageStatus?
    var image: UIImage?
    var isCurrentUser: Bool
    
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
