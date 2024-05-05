//
//  ChatListScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 27/03/24.
//

import SwiftUI

struct ChatListScreen: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var chatListVM = ChatListViewModel()
    
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
            .navigationTitle("Chats")
        }
    }
    
    //MARK: - Chats
    
    @ViewBuilder
    private func Chats() -> some View {
        List {
            ForEach($chatListVM.chats) { $chat in
                NavigationLink(destination: MessageScreen(chatId: chat.id, username: chat.chatName, otherUserUid: chat.otherUserUid, chatPic: chat.chatPic).environmentObject(authVM)) {
                    ChatView(chat: chat).environmentObject(authVM)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                Task {
                                    let token = try await authVM.getFirebaseToken()
                                    await chatListVM.deleteChat(chatId: chat.id, token: token)
                                }
                            } label: {
                                Image(systemName: "trash.fill")
                            }
                            
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
                            }
                            .tint(.blue)
                        }
                }
            }
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
