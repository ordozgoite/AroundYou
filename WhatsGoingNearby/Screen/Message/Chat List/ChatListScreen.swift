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
    @StateObject private var chatListVM = ChatListViewModel()
    @ObservedObject var socket: SocketService
    
    @FetchRequest(fetchRequest: CDFormattedChat.fetch(), animation: .bouncy)
    var chats: FetchedResults<CDFormattedChat>
    @Environment(\.managedObjectContext) var context
    
    var body: some View {
        NavigationStack {
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
            .onChange(of: chatListVM.chats) { chats in
                updateStoredChats(withChats: chats)
            }
            .navigationTitle("Chats")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SocketStatusView(socket: socket)
                }
            }
        }
    }
    
    //MARK: - Chats
    
    @ViewBuilder
    private func Chats() -> some View {
        List {
            if chatListVM.chats.isEmpty {
                ForEach(self.chats) { chat in
                    NavigationLink(destination: MessageScreen(chatId: chat.id ?? "", username: chat.chatName ?? "", otherUserUid: chat.otherUserUid ?? "", chatPic: chat.chatPic, socket: socket)
                        .environmentObject(authVM)
                        .environment(\.managedObjectContext, context)
                    ) {
                        ChatView(chat: chat.convertToFormattedMessage())
                    }
                }
            } else {
                ForEach($chatListVM.chats) { $chat in
                    NavigationLink(destination: MessageScreen(chatId: chat.id, username: chat.chatName, otherUserUid: chat.otherUserUid, chatPic: chat.chatPic, socket: socket)
                        .environmentObject(authVM)
                        .environment(\.managedObjectContext, context)
                    ) {
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
    
    private func updateStoredChats(withChats chats: [FormattedChat]) {
        let fetchRequest: NSFetchRequest<CDFormattedChat> = CDFormattedChat.fetchRequest()
        do {
            let existingChats = try context.fetch(fetchRequest)
            for chat in existingChats {
                context.delete(chat)
            }
            for chat in chats {
                _ = CDFormattedChat(fromChat: chat, context: context)
            }
            PersistenceController.shared.save()
        } catch {
            print("❌ Error fetching existing chats: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ChatListScreen(socket: SocketService())
}
