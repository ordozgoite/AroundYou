//
//  NotificationViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 29/02/24.
//

import Foundation

@MainActor
class NotificationViewModel: ObservableObject {
    
    @Published var notifications: [FormattedNotification] = []
    
    func getNotifications(token: String) async {
        
    }
}
