//
//  WhatsGoingNearbyApp.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import SwiftUI
import FirebaseCore
import FirebaseMessaging
import UserNotifications
import BackgroundTasks

final class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application( _ application: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        Messaging.messaging().isAutoInitEnabled = true
        
        Messaging.messaging().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: { _, _ in })
        
        application.registerForRemoteNotifications()
        
        Messaging.messaging().token { token, error in
            if let error {
                print("Error fetching FCM registration token: \(error)")
            } else if let token {
                print("FCM registration token: \(token)")
            }
        }
        
        scheduleAppRefresh()
        
        print("💾 Last notification: \(LocalState.lastNotificationTime)")
        
        return true
    }
    
    func application(_: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Oh no! Failed to register for remote notifications with error \(error)")
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
        
        let dataDict: [String: String] = ["token": fcmToken ?? ""]
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: dataDict
        )
        
        if let token = fcmToken {
            LocalState.userRegistrationToken = token
        }
    }
}


@main
struct WhatsGoingNearbyApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @ObservedObject public var locationManager = LocationManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .backgroundTask(.appRefresh(taskId)) {
            scheduleAppRefresh()
            if await isPostNearBy() {
                await notifyNearByPost()
            }
        }
    }
    
    func isPostNearBy() async -> Bool {
        if let location = locationManager.location {
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            
            let result = await AYServices.shared.checkNearByPublications(userUid: LocalState.currentUserUid, latitude: latitude, longitude: longitude)
            
            switch result {
            case .success:
                return true
            case .failure:
                return false
            }
        }
        return false
    }
}
