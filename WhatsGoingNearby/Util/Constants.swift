//
//  Constants.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 05/03/24.
//

import Foundation

struct Constants {
    static let appVersion: String = "2.0.0"
    static let maxUsernameLenght: Int = 20
    static let maxNameLenght: Int = 30
    static let maxBioLenght: Int = 250
    static let backgroundTaskDelayHours: Int = 1
    static let notificationDelaySeconds: Int = 4 * 60 * 60
    
    //MARK: - Notification Center
    
    static let scrollToTopNotificationKey: String = "scrollToTop"
    static let refreshFeedNotificationKey: String = "refreshFeed"
}
