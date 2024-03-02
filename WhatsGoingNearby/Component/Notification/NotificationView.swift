//
//  NotificationView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 29/02/24.
//

import SwiftUI

struct NotificationView: View {
    
    let notification: FormattedNotification
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @State private var isUserProfileDisplayed: Bool = false
    
    var body: some View {
        ZStack {
            HStack(alignment: .top) {
                ProfilePicView(profilePic: notification.sendingUserProfilePic)
                    .onTapGesture {
                        isUserProfileDisplayed = true
                    }
                
                VStack(alignment: .leading) {
                    Text(notification.sendingUserName)
                        .fontWeight(.medium)
                    
                    Text(getNotificationText())
                        .fontWeight(.light)
                }
                .padding(.leading, 8)
                
                Spacer()
                
                Text(notification.date.timeAgoDisplay())
                    .foregroundStyle(.gray)
                    .font(.caption)
            }
            
            NavigationLink(
                destination: UserProfileScreen(userUid: notification.sendingUserUid).environmentObject(authVM),
                isActive: $isUserProfileDisplayed,
                label: { EmptyView() }
            ).hidden()
        }
    }
    
    //MARK: - Auxiliary Methods
    
    private func getNotificationText() -> LocalizedStringKey {
        return LocalizedStringKey("\(notification.action.text) your \(notification.target.text)")
    }
}

#Preview {
    NotificationView(notification: FormattedNotification(id: "", sendingUserUid: "", sendingUserName: "Victor Rafael Ordozgoite", sendingUserProfilePic: "https://firebasestorage.googleapis.com:443/v0/b/aroundyou-b8364.appspot.com/o/profile-pic%2FvlzpJ0ir0RXJ6XUO8xLeU54vkGy2.jpg?alt=media&token=18581c9c-4eb8-4f0c-9acd-413fe4f7f01a", action: .like, target: .publication, publicationId: "", notificationDateTime: 1709253250))
}
