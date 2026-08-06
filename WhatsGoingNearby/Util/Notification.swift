//
//  Notification.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 23/02/24.
//

import Foundation
import UserNotifications
import OSLog

private let engagementNotificationLogger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "AroundYou",
    category: "EngagementNotification"
)

enum EngagementNotificationResult {
    case scheduled
    case delayed
    case unauthorized
    case failed
}

public let enNotificationBody: String = "There are posts around you!"
public let ptNotificationBody: String = "Há publicações ao seu redor!"

public func nearByNotification() -> UNNotificationRequest {
    let content = UNMutableNotificationContent()
    content.title = "AroundYou 🌐"
    content.body = LocalState.preferredLanguage.prefix(2) == "pt" ? ptNotificationBody : enNotificationBody
    content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "notification-sound.wav"))
    
    let request = UNNotificationRequest(
        identifier: "nearby_publications_\(UUID().uuidString)",
        content: content,
        trigger: nil
    )
    return request
}

func notifyNearByPost() async -> EngagementNotificationResult {
    let center = UNUserNotificationCenter.current()
    let settings = await center.notificationSettings()
    guard settings.authorizationStatus == .authorized
            || settings.authorizationStatus == .provisional
            || settings.authorizationStatus == .ephemeral
    else {
        engagementNotificationLogger.notice("Local notification not scheduled: authorization unavailable")
        return .unauthorized
    }

    guard !isNotificationInDelay else {
        engagementNotificationLogger.info("Local notification skipped by engagement delay")
        return .delayed
    }

    let notificationRequest = nearByNotification()
    do {
        try await center.add(notificationRequest)
        LocalState.lastNotificationTime = Int(Date().timeIntervalSince1970)
        engagementNotificationLogger.info("Local engagement notification scheduled")
        return .scheduled
    } catch {
        engagementNotificationLogger.error("Local notification scheduling failed: \(error.localizedDescription, privacy: .public)")
        return .failed
    }
}

private var isNotificationInDelay: Bool {
    let now = Int(Date().timeIntervalSince1970)
    let nextNotificationEarliestDate = LocalState.lastNotificationTime + Constants.NOTIFICATION_DELAY_SECONDS
    return now < nextNotificationEarliestDate
}
