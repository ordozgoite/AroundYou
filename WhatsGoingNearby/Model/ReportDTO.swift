//
//  ReportDTO.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 16/02/24.
//

import Foundation

struct ReportDTO: Codable {
    let reporterUserUid: String
    let reportedUserUid: String
    let publicationId: String?
    let commentId: String?
    let reportDescription: String?
}
