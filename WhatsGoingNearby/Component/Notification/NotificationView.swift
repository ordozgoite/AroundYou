//
//  NotificationView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 29/02/24.
//

import SwiftUI

struct NotificationView: View {
    
    let notification: FormattedNotification
    
    var body: some View {
        HStack {
            ProfilePicView(profilePic: notification.sendingUserProfilePic)
            
            VStack(alignment: .leading) {
                Text(notification.sendingUserName)
                    .fontWeight(.medium)
                
                Text(getNotificationText())
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.gray)
        }
    }
    
    //MARK: - Auxiliary Methods
    
    private func getNotificationText() -> LocalizedStringKey {
        return LocalizedStringKey("\(notification.action.text) your \(notification.target.text)")
    }
}

#Preview {
    NotificationView(notification: FormattedNotification(id: "", sendingUserName: "Victor Rafael Ordozgoite", sendingUserProfilePic: "https://firebasestorage.googleapis.com:443/v0/b/aroundyou-b8364.appspot.com/o/profile-pic%2FvlzpJ0ir0RXJ6XUO8xLeU54vkGy2.jpg?alt=media&token=18581c9c-4eb8-4f0c-9acd-413fe4f7f01a", action: .like, target: .publication, targetId: ""))
}
