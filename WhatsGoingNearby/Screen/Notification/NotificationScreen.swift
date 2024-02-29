//
//  NotificationScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 29/02/24.
//

import SwiftUI

struct NotificationScreen: View {
    
    @StateObject private var notificationVM = NotificationViewModel()
    @EnvironmentObject var authVM: AuthenticationViewModel
    
    var body: some View {
        VStack {
            List {
                ForEach(notificationVM.notifications) { notification in
                    NotificationView(notification: notification)
                }
            }
        }
        .navigationTitle("Notifications")
        .onAppear {
            Task {
                let token = try await authVM.getFirebaseToken()
                await notificationVM.getNotifications(token: token)
            }
        }
    }
}

#Preview {
    NotificationScreen()
}
