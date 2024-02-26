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

public let taskId = "ordozgoite.WhatsGoingNearby.backgroundTask"

public func nearByNotification() -> UNNotificationRequest {
    let content = UNMutableNotificationContent()
    content.title = "AroundYou 🌐"
    content.body = "There are new posts around you!"
    content.sound = .default
    let request = UNNotificationRequest(identifier: "nearby_publications", content: content, trigger: nil)
    return request
}

public func scheduleAppRefresh() {
    let now = Date()
    let oneHourFromNow = Calendar.current.date(byAdding: .hour, value: 1, to: now)!
    
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
    let notificationRequest = nearByNotification()
    do {
        try await UNUserNotificationCenter.current().add(notificationRequest)
    } catch {
        print("Notification failed with error: \(String(describing: error))")
    }
}

public func checkNotificationDelayPassed() -> Bool {
    let minDelayInSeconds = 43200
    let now = Int(Date().timeIntervalSince1970)
    return now > LocalState.lastNotificationTime + minDelayInSeconds
}
