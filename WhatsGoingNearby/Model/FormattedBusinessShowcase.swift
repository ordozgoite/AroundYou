//
//  FormattedBusinessShowcase.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 26/02/25.
//

import Foundation

struct FormattedBusinessShowcase: Codable {
    let id: String
    let imageUrl: String?
    let showcaseTitle: String
    let description: String
//    let category: BusinessCategory
    let latitude: Double
    let longitude: Double
//    let contactMethod: BusinessShowcaseContactMethod
    let phoneNumber: String?
    let websiteLink: String?
}
