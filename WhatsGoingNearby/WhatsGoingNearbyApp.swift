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

    private let locationManager = LocationManager.shared

    func application( _ application: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // FirebaseApp.configure()
        
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
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Constants.updateLocBGTaskId, using: nil) { task in
            guard let task = task as? BGAppRefreshTask else { return }
            self.handleTask(task: task)
        }
        
        schedule()

        printBGTaskStats()

        return true
    }

    private func printBGTaskStats() {
        print("📊 [BGTask] Agendamentos: \(LocalState.bgTaskScheduledCount)")
        print("📊 [BGTask] Execuções: \(LocalState.bgTaskRunCount)")
        print("📊 [BGTask] Erros: \(LocalState.bgTaskErrorCount)")
        print("📊 [BGTask] Notificações de engajamento enviadas: \(LocalState.engagementNotificationCount)")
        print("💾 [BGTask] Última notificação: \(LocalState.lastNotificationTime)")
    }

    private func handleTask(task: BGAppRefreshTask) {
        LocalState.bgTaskRunCount += 1

        schedule()

        let work = Task {
            switch await checkNearByPost() {
            case .postFound:
                if await notifyNearByPost() {
                    LocalState.engagementNotificationCount += 1
                }
            case .noPostFound:
                break
            case .error:
                LocalState.bgTaskErrorCount += 1
            }
            task.setTaskCompleted(success: true)
        }

        task.expirationHandler = {
            work.cancel()
            LocalState.bgTaskErrorCount += 1
            task.setTaskCompleted(success: false)
        }
    }

    private func schedule() {
        let now = Date()
        let nextBGTaskTime = Calendar.current.date(byAdding: .hour, value: Constants.BACKGROUND_TASK_DELAY_HOURS, to: now)!

        BGTaskScheduler.shared.getPendingTaskRequests { requests in
            print("\(requests.count) BGTasks pending...")
            guard requests.isEmpty else { return }

            do {
                let newTask = BGAppRefreshTaskRequest(identifier: Constants.updateLocBGTaskId)
                newTask.earliestBeginDate = nextBGTaskTime
                try BGTaskScheduler.shared.submit(newTask)
                LocalState.bgTaskScheduledCount += 1
                print("✅ Task scheduled!")
            } catch {
                LocalState.bgTaskErrorCount += 1
                print("❌ Failed to schedule: \(error)")
            }
        }
    }

    private enum NearByCheckResult {
        case postFound
        case noPostFound
        case error
    }

    private func checkNearByPost() async -> NearByCheckResult {
        guard let location = await locationManager.getCurrentLocation() else { return .error }

        let result = await AYServices.shared.checkNearByPublications(
            userUid: LocalState.currentUserUid,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )

        switch result {
        case .success:
            return .postFound
        case .failure(.dataNotFound):
            return .noPostFound
        case .failure:
            return .error
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
        
        if let token = fcmToken {
            LocalState.userRegistrationToken = token
        }
    }
}


@main
struct WhatsGoingNearbyApp: App {
    init() {
        FirebaseApp.configure()
        print("✅ Firebase configured in App init")
    }
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject var notificationManager = NotificationManager()
    @StateObject var authVM = AuthenticationViewModel()
    @StateObject private var socket = SocketService.shared
    @StateObject private var locationManager = LocationManager.shared
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
    }
}
