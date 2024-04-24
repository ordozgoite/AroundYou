//
//  FormattedMessage.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 28/03/24.
//

import Foundation
import SwiftUI

struct FormattedMessage: Identifiable, Equatable, Hashable {
    let id: String
    let chatId: String
    var message: String?
    var imageUrl: String?
    var isCurrentUser: Bool
    var isFirst: Bool
    var repliedMessageText: String?
    var repliedMessageId: String?
    var timeDivider: Int?
    var image: UIImage?
    var status: MessageStatus
}
