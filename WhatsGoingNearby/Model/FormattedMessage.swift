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
    var isCurrentUser: Bool
    var isFirst: Bool
    var repliedMessageText: String?
    var timeDivider: Int?
}
