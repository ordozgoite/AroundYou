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
    @ObservedObject var socket: SocketService
    
    var body: some View {
        ZStack {
            HStack(alignment: .top) {
                ProfilePicView(profilePic: notification.sendingUserProfilePic)
                    .onTapGesture {
                        isUserProfileDisplayed = true
                    }
                
                NotificationText()
                
                Spacer()
                
                Text(notification.date.timeAgoDisplay())
                    .foregroundStyle(.gray)
                    .font(.caption)
            }
            
            NavigationLink(
                destination: UserProfileScreen(userUid: notification.sendingUserUid, socket: socket).environmentObject(authVM),
                isActive: $isUserProfileDisplayed,
                label: { EmptyView() }
            ).hidden()
        }
    }
    
    //MARK: - Body
    
    @ViewBuilder
    private func NotificationText() -> some View {
        VStack(alignment: .leading) {
            Text(notification.sendingUsername)
                .fontWeight(.medium)
            
            Text(notification.action.text)
                .fontWeight(.light)
            +
            Text(notification.target.text)
                .fontWeight(.light)
        }
        .padding(.leading, 8)
    }
}

#Preview {
    NotificationView(notification: FormattedNotification(id: "", sendingUserUid: "", sendingUsername: "ordozgoite", sendingUserProfilePic: "https://firebasestorage.googleapis.com:443/v0/b/aroundyou-b8364.appspot.com/o/profile-pic%2FvlzpJ0ir0RXJ6XUO8xLeU54vkGy2.jpg?alt=media&token=18581c9c-4eb8-4f0c-9acd-413fe4f7f01a", action: .like, target: .publication, publicationId: "", notificationDateTime: 1709253250), socket: SocketService())
}
