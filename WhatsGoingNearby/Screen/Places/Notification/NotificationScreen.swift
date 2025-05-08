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
    @ObservedObject var socket: SocketService
    @ObservedObject var locationManager: LocationManager
    
    var body: some View {
        ZStack {
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
            
            AYErrorAlert(message: notificationVM.overlayError.1, isErrorAlertPresented: $notificationVM.overlayError.0)
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
        List {
            ForEach(notificationVM.notifications) { notification in
                NavigationLink(destination: IndepCommentScreen(postId: notification.publicationId, locationManager: locationManager, socket: socket)) {
                    NotificationView(notification: notification, socket: socket)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                Task {
                                    let token = try await authVM.getFirebaseToken()
                                    await notificationVM.deleteNotification(notificationId: notification.id, token: token)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
    }
}
