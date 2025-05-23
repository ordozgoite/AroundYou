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
    
    var isReady: Bool = false
    var pendingPayload: (() -> Void)? = nil
    
    // Comment
    @Published var publicationId: String?
    @Published var isPublicationDisplayed: Bool = false
    
    // Message
    @Published var chatId: String?
    @Published var username: String?
    @Published var senderUserUid: String?
    @Published var chatPic: String?
    @Published var isLocked: Bool?
    @Published var isChatDisplayed: Bool = false
    
    // Community Message
    @Published var communityId: String?
    @Published var communityName: String?
    @Published var communityImageUrl: String?
    @Published var isCommunityChatDisplayed: Bool = false
    
    // Discover
    @Published var isPeopleTabDisplayed: Bool = false
    
    override init() {
        super.init()
        notificationCenter.delegate = self
    }
    
}

// MARK: - Payload

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
        if let nextView = userInfo["screenToShow"] as? String {
            switch nextView {
            case "comment":
                displayCommentScreen(with: userInfo)
            case "message":
                displayMessageScreen(with: userInfo)
            case "communityMessage":
                displayCommunityMessageScreen(with: userInfo)
            case "discover":
                goToPeopleTab()
            default:
                print("❌ Unknown user info received.")
            }
        }
    }
}

// MARK: - Screen

extension NotificationManager {
    private func displayCommentScreen(with userInfo: [AnyHashable: Any]) {
        if let publicationId = userInfo["publicationId"] as? String {
            self.publicationId = publicationId
            self.isPublicationDisplayed = true
        } else {
            print("❌ Incorrect userInfo to display Comment screen.")
        }
    }
    
    private func displayMessageScreen(with userInfo: [AnyHashable: Any]) {
        let displayBlock = {
            if
                let chatId = userInfo["chatId"] as? String,
                let username = userInfo["username"] as? String,
                let senderUserUid = userInfo["senderUserUid"] as? String,
                let isLocked = userInfo["isLocked"] as? Bool
            {
                self.chatId = chatId
                self.username = username
                self.senderUserUid = senderUserUid
                self.isLocked = isLocked
                if let chatPic = userInfo["chatPic"] as? String { self.chatPic = chatPic }
                self.isChatDisplayed = true
            } else {
                print("❌ Incorrect userInfo to display Message screen.")
            }
        }

        if isReady {
            displayBlock()
        } else {
            pendingPayload = displayBlock
        }
    }

    
    private func displayCommunityMessageScreen(with userInfo: [AnyHashable: Any]) {
        if
            let communityId = userInfo["communityId"] as? String,
            let communityName = userInfo["communityName"] as? String
        {
            self.communityId = communityId
            self.communityName = communityName
            if let communityImageUrl = userInfo["communityImageUrl"] as? String { self.communityImageUrl = communityImageUrl }
            self.isCommunityChatDisplayed = true
        } else {
            print("❌ Incorrect userInfo to display Message screen.")
        }
    }
    
    private func goToPeopleTab() {
        self.isPeopleTabDisplayed = true
    }
}
