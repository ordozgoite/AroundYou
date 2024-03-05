//
//  NotificationManager.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 28/02/24.
//

import Foundation
import SwiftUI
import NotificationCenter

@MainActor
class NotificationManager: NSObject, ObservableObject {
    
    let notificationCenter = UNUserNotificationCenter.current()
    @Published var nextView: NextView?
    @Published var id: String?
    @Published var isPublicationDisplayed: Bool = false
    
    override init() {
        super.init()
        notificationCenter.delegate = self
    }
    
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_: UNUserNotificationCenter, willPresent _: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let options: UNNotificationPresentationOptions = [.badge, .banner, .sound]
        completionHandler(options)
    }
    
    func userNotificationCenter(_: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        processNotificationPayload(userInfo: userInfo)
        NotificationCenter.default.post(
            name: Notification.Name("didReceiveRemoteNotification"),
            object: nil,
            userInfo: userInfo
        )
        completionHandler()
    }
    
    private func processNotificationPayload(userInfo: [AnyHashable: Any]) {
        if let nextView = userInfo["screenToShow"] as? String, let commentId = userInfo["commentId"] as? String {
            self.nextView = NextView(rawValue: nextView)
            self.id = commentId
            self.isPublicationDisplayed = true
        }
    }
}
