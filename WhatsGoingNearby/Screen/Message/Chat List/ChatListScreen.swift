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
                    Chats()
                }
            }
            .onAppear {
                startUpdatingChats()
            }
            .onDisappear {
                stopUpdatingChats()
            }
            .navigationTitle("Messages")
        }
    }
    
    //MARK: - Chats
    
    @ViewBuilder
    private func Chats() -> some View {
        ScrollView {
            ForEach($chatListVM.chats) { $chat in
                NavigationLink(destination: MessageScreen(chatId: chat.id, username: chat.chatName, otherUserUid: chat.otherUserUid, chatPic: chat.chatPic).environmentObject(authVM)) {
                    ChatView(chat: chat).environmentObject(authVM)
                        .contextMenu {
                            Button {
                                Task {
                                    let token = try await authVM.getFirebaseToken()
                                    if chat.isMuted {
                                        await chatListVM.unmuteChat(chatId: chat.id, token: token)
                                    } else {
                                        await chatListVM.muteChat(chatId: chat.id, token: token)
                                    }
                                }
                            } label: {
                                Image(systemName: chat.isMuted ? "bell.fill" : "bell.slash.fill")
                                Text(chat.isMuted ? "Unmute Chat" : "Mute Chat")
                            }
                        }
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    //MARK: - Private Method
    
    private func startUpdatingChats() {
        chatListVM.chatTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            Task {
                try await updateChats()
            }
        }
        chatListVM.chatTimer?.fire()
    }
    
    private func updateChats() async throws {
        let token = try await authVM.getFirebaseToken()
        await chatListVM.getChats(token: token)
    }
    
    private func stopUpdatingChats() {
        chatListVM.chatTimer?.invalidate()
    }
}

#Preview {
    ChatListScreen()
}
