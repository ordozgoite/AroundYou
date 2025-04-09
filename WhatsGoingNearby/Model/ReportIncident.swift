//
//  ReportIncident.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 09/04/25.
//

import Foundation

struct ReportIncident {
    let type: IncidentType
    let description: String
    let latitude: Double
    let longitude: Double
    let isUserTheVictim: Bool?
    let humanVictimDetails: String?
    let imageUrl: String?
}
