//
//  Constants.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 05/03/24.
//

import Foundation
import CoreLocation

//"https://around-you-3acb9615e8a5.herokuapp.com"
//"http://localhost:3000"

struct Constants {
    static let serverUrl: String = "https://around-you-3acb9615e8a5.herokuapp.com"
    
    // MARK: -  User
    
    static let maxUsernameLenght: Int = 20
    static let maxNameLenght: Int = 30
    static let maxBioLenght: Int = 250
    
    // MARK: - Feed
    
    static let maxPostLength = 250
    
    // MARK: - Time and Distance
    
    static let backgroundTaskDelayHours: Int = 1
    static let notificationDelaySeconds: Int = 4 * 60 * 60
    static let significantDistanceMeters: CLLocationDistance = 50
    static let maximumElapsedTimeToDeleteMessageInSeconds: Int = 60
    
    //MARK: - Notification Center
    
    static let refreshLocationSensitiveDataNotificationKey: String = "refreshFeed"
    static let updateLocationNotificationKey: String = "updateLocation"
    static let updateBadgeNotificationKey: String = "updateBadge"
    
    //MARK: - Discover Defaults
    
    static let defaultUserAge: Int = 18
    static let defaultMinAgePreference: Int = 25
    static let defaultMaxAgePreference: Int = 40
}
