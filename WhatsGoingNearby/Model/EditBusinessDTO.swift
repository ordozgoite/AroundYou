//
//  EditBusinessDTO.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 26/05/25.
//

import Foundation

struct EditBusinessDTO {
    let businessId: String
    let description : String?
    let category: String
    let isLocationVisible: Bool
    let title: String
    let instagramUsername: String?
    let whatsAppNumber: String?
    let phoneNumber: String?
}
