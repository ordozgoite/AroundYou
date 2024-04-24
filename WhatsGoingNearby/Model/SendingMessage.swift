//
//  SendingMessage.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 23/04/24.
//

import Foundation
import SwiftUI

struct SendingMessage {
    let id: String
    let chatId: String
    let senderUserUid: String
    let text: String?
    let imageUrl: String?
    let isRead: Bool
    let createdAt: Int
    let repliedMessageId: String?
    let repliedMessageText: String?
    var status: MessageStatus?
    let image: UIImage?
}
