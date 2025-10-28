//
//  ChatMessageFromNotificationView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 30/05/25.
//

import SwiftUI

struct ChatMessageFromNotificationView: View {
    let chat: FormattedChat
    @EnvironmentObject var navCoordinator: NavigationCoordinator
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationStack(path: $navCoordinator.path) {
            MessageScreen(
                chatId: chat.id,
                username: chat.chatName,
                otherUserUid: chat.otherUserUid,
                chatPic: chat.chatPic,
                isLocked: chat.isLocked
            )
            .navigationBarItems(leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }, label: {
                Image(systemName: "xmark")
            }))
            .navigationDestination(for: AppRoute.self) { destination in
                switch destination {
                case .userProfile(chat.otherUserUid):
                    UserProfileScreen(userUid: chat.otherUserUid)
                case .messages(let chat):
                    MessageScreen(
                        chatId: chat.id,
                        username: chat.chatName,
                        otherUserUid: chat.otherUserUid,
                        chatPic: chat.chatPic,
                        isLocked: chat.isLocked
                    )
                default:
                    EmptyView()
                }
            }
        }
        
    }
}

//#Preview {
//    ChatMessageFromNotificationView()
//}
