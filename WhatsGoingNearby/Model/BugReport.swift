//
//  BugReport.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 17/02/24.
//

import Foundation

struct BugReport: Codable {
    let userUid: String
    let bugDescription: String
    let reportDateTime: String
}
