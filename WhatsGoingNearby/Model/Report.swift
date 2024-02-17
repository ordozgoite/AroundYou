//
//  Report.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 16/02/24.
//

import Foundation

struct Report: Codable {
    let reporterUserUid: String
    let reportedUserUid: String
    let publicationId: String?
    let commentId: String?
    let reportDescription: String?
    let reportStatus: String
    let reportDateTime: String
}
