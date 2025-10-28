//
//  MessageScreenWrapper.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 26/02/25.
//

import SwiftUI

struct MessageScreenWrapper: View {
    let chatId: String
    let username: String
    let otherUserUid: String
    let chatPic: String?
    let isLocked: Bool
    @EnvironmentObject var navCoordinator: NavigationCoordinator
    @EnvironmentObject var socket: SocketService
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationStack(path: $navCoordinator.path) {
            MessageScreen(
                chatId: chatId,
                username: username,
                otherUserUid: otherUserUid,
                chatPic: chatPic,
                isLocked: isLocked
            )
            .navigationBarItems(leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }, label: {
                Image(systemName: "xmark")
            }))
            .navigationDestination(for: AppRoute.self) { destination in
                switch destination {
                case .userProfile(otherUserUid):
                    UserProfileScreen(userUid: otherUserUid)
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
