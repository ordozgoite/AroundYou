//
//  NotificationViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 29/02/24.
//

import Foundation
import SwiftUI

@MainActor
class NotificationViewModel: ObservableObject {
    
    @Published var notifications: [FormattedNotification] = []
    @Published var isLoading: Bool = false
    @Published var isNotificationsFetched: Bool = false
    @Published var overlayError: (Bool, LocalizedStringKey) = (false, "")
    
    func getNotifications(token: String) async {
        isLoading = true
        let result = await AYServices.shared.getUserNotifications(token: token)
        isLoading = false
        
        switch result {
        case .success(let notifications):
            self.notifications = notifications
            isNotificationsFetched = true
        case .failure:
            overlayError = (true, ErrorMessage.getNotifications)
        }
    }
    
    func deleteNotification(notificationId: String, token: String) async {
        let result = await AYServices.shared.deleteNotification(notificationId: notificationId, token: token)
        
        switch result {
        case .success:
            notifications = notifications.filter { $0.id != notificationId }
        case .failure:
            overlayError = (true, ErrorMessage.deleteNotification)
        }
    }
}
