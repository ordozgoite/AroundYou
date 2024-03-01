//
//  NotificationScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 29/02/24.
//

import SwiftUI
import CoreLocation

struct NotificationScreen: View {
    
    @StateObject private var notificationVM = NotificationViewModel()
    @EnvironmentObject var authVM: AuthenticationViewModel
    @Binding var location: CLLocation?
    
    var body: some View {
        VStack {
            if notificationVM.isLoading {
                ProgressView()
            } else {
                if notificationVM.notifications.isEmpty {
                    EmptyNotifications()
                } else {
                    Notifications()
                }
            }
        }
        .navigationTitle("Notifications")
        .onAppear {
            if !notificationVM.isNotificationsFetched {
                Task {
                    let token = try await authVM.getFirebaseToken()
                    await notificationVM.getNotifications(token: token)
                }
            }
        }
    }
    
    //MARK: - Empty View
    
    @ViewBuilder
    private func EmptyNotifications() -> some View {
        Text("You have no notifications yet.")
            .foregroundStyle(.gray)
            .fontWeight(.semibold)
    }
    
    //MARK: - Notifications
    
    @ViewBuilder
    private func Notifications() -> some View {
        ScrollView {
            ForEach(notificationVM.notifications) { notification in
                NavigationLink(destination: PostScreen(postId: notification.targetId, location: $location)) {
                    NotificationView(notification: notification)
                        .padding()
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
            }
        }
    }
}
