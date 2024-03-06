//
//  Notification.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 23/02/24.
//

import Foundation
import UserNotifications
import CoreLocation
import BackgroundTasks
import SwiftUI

public let taskId = "ordozgoite.WhatsGoingNearby.backgroundTask"
public let enNotificationBody: String = "There are new posts around you!"
public let ptNotificationBody: String = "Há novas publicações perto de você!"

public func nearByNotification() -> UNNotificationRequest {
    let content = UNMutableNotificationContent()
    content.title = "AroundYou 🌐"
    content.body = LocalState.preferredLanguage.prefix(2) == "pt" ? ptNotificationBody : enNotificationBody
    content.sound = .default
    let request = UNNotificationRequest(identifier: "nearby_publications", content: content, trigger: nil)
    return request
}

public func scheduleAppRefresh() {
    let now = Date()
    let oneHourFromNow = Calendar.current.date(byAdding: .hour, value: Constants.backgroundTaskDelayHours, to: now)!
    
    do {
        let request = BGAppRefreshTaskRequest(identifier: taskId)
        request.earliestBeginDate = oneHourFromNow
        try BGTaskScheduler.shared.submit(request)
        print("✅ Task scheduled!")
    } catch {
        print("❌ Failed to schedule: \(error)")
    }
}

public func notifyNearByPost() async {
    if isNotificationInDelay { return }
    
    let notificationRequest = nearByNotification()
    do {
        try await UNUserNotificationCenter.current().add(notificationRequest)
    } catch {
        print("Notification failed with error: \(String(describing: error))")
    }
}

private var isNotificationInDelay: Bool {
    let now = Int(Date().timeIntervalSince1970)
    let nextNotificationEarliestDate = LocalState.lastNotificationTime + Constants.notificationDelaySeconds
    return now < nextNotificationEarliestDate
}
