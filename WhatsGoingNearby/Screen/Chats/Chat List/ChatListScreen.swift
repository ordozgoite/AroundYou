//
//  ChatListScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 27/03/24.
//

import SwiftUI
import CoreData

struct ChatListScreen: View {
    @EnvironmentObject var authVM: AuthenticationViewModel
    @EnvironmentObject var socket: SocketService
    @EnvironmentObject var navCoordinator: NavigationCoordinator
    @StateObject private var chatListVM = ChatListViewModel()
    
    var body: some View {
        NavigationStack(path: $navCoordinator.path) {
            ZStack {
                Chats()
            }
            .onAppear {
                updateChats()
                listenToMessages()
            }
            .onChange(of: socket.status) { status in
                if status == .connected {
                    updateChats()
                }
            }
            .navigationTitle("Chats")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SocketStatusView()
                }
            }
            .navigationDestination(for: AppRoute.self) { destination in
                switch destination {
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
    
    //MARK: - Chats
    
    @ViewBuilder
    private func Chats() -> some View {
        List {
            if !chatListVM.chats.isEmpty {
                ForEach($chatListVM.chats) { $chat in
                    ChatView(chat: chat).environmentObject(authVM)
                        .onTapGesture {
                            print("⚠️ Tocou no chat!")
                            navCoordinator.navigate(to: .messages(chat))
                        }
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
    
    private func updateChats() {
        Task {
            let token = try await authVM.getFirebaseToken()
            await chatListVM.getChats(token: token)
        }
    }
    
    private func listenToMessages() {
        print("⚠️ listenToMessages")
        socket.socket?.on("chat") { data, ack in
            print("⚠️ updateChats")
            updateChats()
        }
    }
}

#Preview {
    ChatListScreen()
}
