//
//  Constants.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 05/03/24.
//

import Foundation
import CoreLocation

struct Constants {
    static let appVersion: String = "2.1.2"
    static let maxUsernameLenght: Int = 20
    static let maxNameLenght: Int = 30
    static let maxBioLenght: Int = 250
    static let backgroundTaskDelayHours: Int = 1
    static let notificationDelaySeconds: Int = 4 * 60 * 60
    static let significantDistanceMeters: CLLocationDistance = 50
    
    //MARK: - Notification Center
    
    static let refreshFeedNotificationKey: String = "refreshFeed"
    static let updateLocationNotificationKey: String = "updateLocation"
}
