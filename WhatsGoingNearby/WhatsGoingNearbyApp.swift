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
    
    let taskId = "ordozgoite.WhatsGoingNearby.backgroundTask"
    @ObservedObject var locationManager = LocationManager()
    
    func application( _ application: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        Messaging.messaging().isAutoInitEnabled = true
        
        Messaging.messaging().delegate = self
        
        UNUserNotificationCenter.current().delegate = self
        
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
        
        // Background Fetch
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskId, using: nil) { task in
            guard let task = task as? BGAppRefreshTask else { return }
            Task {
                await self.handleTask(task)
            }
        }
        
        print("🔄 Task ran \(LocalState.taskRunCount) times!")
        
        schedule()
        
        return true
    }
    
    private func handleTask(_ task: BGAppRefreshTask) async {
        if let location = locationManager.location {
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            
            if !LocalState.currentUserUid.isEmpty {
                let result = await AYServices.shared.checkNearByPublications(userUid: LocalState.currentUserUid, latitude: latitude, longitude: longitude)
                
                switch result {
                case .success:
                    displayNotification()
                case .failure(let error):
                    print("❌ Error: \(error)")
                }
            }
        }
        
        LocalState.taskRunCount += 1
        // make request
        task.setTaskCompleted(success: true)
    }
    
    private func displayNotification() {
        let content = UNMutableNotificationContent()
        content.title = "AroundYou 🌐"
        content.body = "Você tem novas publicações próximas!"
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: "nearby_publications", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error adding notification request: \(error.localizedDescription)")
            }
        }
    }
    
    private func schedule() {
        BGTaskScheduler.shared.getPendingTaskRequests { requests in
            print("\(requests.count) BGTasks pending...")
            guard requests.isEmpty else {
                return
            }
            do {
                let newTask = BGAppRefreshTaskRequest(identifier: self.taskId)
                newTask.earliestBeginDate = Date().addingTimeInterval(300)
                try BGTaskScheduler.shared.submit(newTask)
                print("✅ Task scheduled!")
            } catch {
                print("❌ Failed to schedule: \(error)")
            }
        }
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
        // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app startup and whenever a new token is generated.
        
        if let token = fcmToken {
            LocalState.userRegistrationToken = token
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_: UNUserNotificationCenter, willPresent _: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let options: UNNotificationPresentationOptions = [.badge, .banner, .sound]
        completionHandler(options)
    }
    
    func userNotificationCenter(
        _: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        NotificationCenter.default.post(
            name: Notification.Name("didReceiveRemoteNotification"),
            object: nil,
            userInfo: userInfo
        )
        completionHandler()
    }
}


@main
struct WhatsGoingNearbyApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
