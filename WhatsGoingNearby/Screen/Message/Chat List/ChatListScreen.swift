//
//  ChatListScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 27/03/24.
//

import SwiftUI

struct ChatListScreen: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @ObservedObject private var chatListVM = ChatListViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                if chatListVM.isLoading {
                    ProgressView()
                } else {
                    ScrollView {
                        ForEach($chatListVM.chats) { $chat in
                            NavigationLink(destination: MessageScreen(chatId: chat.id, username: chat.chatName, otherUserUid: chat.otherUserUid).environmentObject(authVM)) {
                                ChatView(chat: chat)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .onAppear {
                Task {
                    let token = try await authVM.getFirebaseToken()
                    await chatListVM.getChats(token: token)
                }
            }
            .navigationTitle("Messages")
        }
        
    }
}

#Preview {
    ChatListScreen()
}
