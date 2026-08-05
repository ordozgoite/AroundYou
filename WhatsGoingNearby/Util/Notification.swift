//
//  Notification.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 23/02/24.
//

import Foundation
import UserNotifications

public let enNotificationBody: String = "There are posts around you!"
public let ptNotificationBody: String = "Há publicações ao seu redor!"

public func nearByNotification() -> UNNotificationRequest {
    let content = UNMutableNotificationContent()
    content.title = "AroundYou 🌐"
    content.body = LocalState.preferredLanguage.prefix(2) == "pt" ? ptNotificationBody : enNotificationBody
    content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "notification-sound.wav"))
    
    let request = UNNotificationRequest(identifier: "nearby_publications", content: content, trigger: nil)
    return request
}

@discardableResult
public func notifyNearByPost() async -> Bool {
    if isNotificationInDelay { return false }

    let notificationRequest = nearByNotification()
    do {
        try await UNUserNotificationCenter.current().add(notificationRequest)
        LocalState.lastNotificationTime = Int(Date().timeIntervalSince1970)
        return true
    } catch {
        print("Notification failed with error: \(String(describing: error))")
        return false
    }
}

private var isNotificationInDelay: Bool {
    let now = Int(Date().timeIntervalSince1970)
    let nextNotificationEarliestDate = LocalState.lastNotificationTime + Constants.NOTIFICATION_DELAY_SECONDS
    return now < nextNotificationEarliestDate
}
