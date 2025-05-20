//
//  Constants.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 05/03/24.
//

import Foundation
import CoreLocation

extension Notification.Name {
    static let refreshLocationSensitiveData = Notification.Name("refreshFeed")
    static let updateLocation = Notification.Name("updateLocation")
    static let updateBadge = Notification.Name("updateBadge")
    static let popCommunity = Notification.Name("popCommunity")
    static let goToUsernameScreen = Notification.Name("goToUsernameScreen")
    static let displayRetryGetUserInfoButton = Notification.Name("displayRetryGetUserInfoButton")
}

struct Constants {
    static let API_URL: String = "https://around-you-3acb9615e8a5.herokuapp.com"
    
    // MARK: - Images
    
    static let instagramLogoImageName: String = "instagram"
    static let whatsAppLogoImageName: String = "whatsapp"
    
    // MARK: -  User
    
    static let MAX_USERNAME_LENGHT: Int = 20
    static let MAX_NAME_LENGHT: Int = 30
    static let MAX_BIO_LENGHT: Int = 250
    
    // MARK: - Feed
    
    static let MAX_POST_LENGHT = 250
    
    // MARK: - Time and Distance
    
    static let BACKGROUND_TASK_DELAY_HOURS: Int = 1
    static let NOTIFICATION_DELAY_SECONDS: Int = 4 * 60 * 60
    static let SIGNIFICANT_DISTANCE_METERS: CLLocationDistance = 50
    static let MAX_ELAPSED_TIME_DELETE_MESSAGE_SECONDS: Int = 60
    
    //MARK: - Discover Defaults
    
    static let DEFAULT_USER_AGE: Int = 18
    static let DEFAULT_MIN_AGE_PREFERENCE: Int = 25
    static let DEFAULT_MAX_AGE_PREFERENCE: Int = 40
    static let minDiscoverAge: Int = 18
    static let maxDiscoverAge: Int = 99
    
    // MARK: - Community
    
    static let communityDiscaimerMessageId: String = "community_disclaimer_message_id"
    
    // MARK: - Icons
    
    static let communityIconImageName: String = "bubble.left.and.bubble.right"
}
