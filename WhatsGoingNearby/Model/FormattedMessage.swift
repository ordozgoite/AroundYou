//
//  FormattedMessage.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 28/03/24.
//

import Foundation

struct FormattedMessage: Codable, Identifiable, Equatable, Hashable {
    let id: String
    var message: String?
    var imageUrl: String?
    var isCurrentUser: Bool // format
    var isFirst: Bool // format
    var repliedMessageText: String?
    var repliedMessageId: String?
    var timeDivider: Int? // format
}
