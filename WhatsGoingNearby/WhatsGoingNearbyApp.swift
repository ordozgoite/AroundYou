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
    
    @StateObject private var locationManager = LocationManager()
    
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
        
        /*
        Função scheduleAppRefresh começou a lançar uma exceção após a atualização do iOS 18.4.
         TODO: Corrigir erro!
        */
//        scheduleAppRefresh()
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Constants.updateLocBGTaskId, using: nil) { task in
            guard let task = task as? BGAppRefreshTask else { return }
            self.handleTask(task: task)
        }
        
        schedule()
        
        
        print("💾 Last notification: \(LocalState.lastNotificationTime)")
        
        return true
    }
    
    private func handleTask(task: BGAppRefreshTask) {
        let count = LocalState.lastNotificationTime
        LocalState.lastNotificationTime = count + 1
        
        schedule()
        Task {
            if await isPostNearBy() {
                await notifyNearByPost()
            }
        }
        
        task.setTaskCompleted(success: true)
    }
    
    private func schedule() {
        BGTaskScheduler.shared.getPendingTaskRequests { requests in
            print("\(requests.count) BGTasks pending...")
            guard requests.isEmpty else { return }
        }
        
        let now = Date()
        let nextBGTaskTime = Calendar.current.date(byAdding: .hour, value: Constants.BACKGROUND_TASK_DELAY_HOURS, to: now)!
        
        do {
            let newTask = BGAppRefreshTaskRequest(identifier: Constants.updateLocBGTaskId)
            newTask.earliestBeginDate = nextBGTaskTime
            try BGTaskScheduler.shared.submit(newTask)
            print("✅ Task scheduled!")
        } catch {
            print("❌ Failed to schedule: \(error)")
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
    
    @StateObject var notificationManager = NotificationManager()
    @StateObject var authVM = AuthenticationViewModel()
    @StateObject private var socket = SocketService.shared
    @StateObject private var locationManager = LocationManager()
    @StateObject private var placesVM = PlacesViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(notificationManager)
                .environmentObject(authVM)
                .environmentObject(socket)
                .environmentObject(locationManager)
                .environmentObject(placesVM)
        }
//        .backgroundTask(.appRefresh(Constants.updateLocBGTaskId)) {
//            scheduleAppRefresh()
//            if await isPostNearBy() {
//                await notifyNearByPost()
//            }
//        }
    }
}
