//
//  FormattedMessage.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 28/03/24.
//

import Foundation

struct FormattedMessage: Codable, Identifiable {
    let id: String
    var message: String
    var isCurrentUser: Bool
    var isFirst: Bool
}
