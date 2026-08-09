//
//  ChatListScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 27/03/24.
//

import SwiftUI
import CoreData

struct ChatListScreen: View {
    private static let listenerOwner = "chat-list"

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
                listenToMessages()
                updateChats()
            }
            .onChange(of: socket.resyncSignal) { _ in
                updateChats()
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
                    // A conversa é empurrada por cima da estrutura de abas, como no iMessage:
                    // a tab bar sai do layout (sem reservar altura) e volta sozinha no pop,
                    // deixando o composer encostado apenas na safe area inferior.
                    .toolbar(.hidden, for: .tabBar)
                case .userProfile(let userUid):
                    UserProfileScreen(userUid: userUid)
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
                        .contentShape(Rectangle())
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
    
    /// A lista tem uma instância só, então o dono é fixo; registrar de novo substitui o
    /// handler anterior em vez de empilhar mais uma atualização por evento recebido.
    private func listenToMessages() {
        socket.addListener(for: "chat", owner: Self.listenerOwner) { data, ack in
            RealtimeLog.eventReceived("chat", chatId: nil)
            updateChats()
        }

        // Uma mensagem em qualquer conversa também atualiza a lista, inclusive quando ela
        // chega para uma conversa que não está aberta.
        socket.addListener(for: "message", owner: Self.listenerOwner) { data, ack in
            updateChats()
        }
    }
}

#Preview {
    ChatListScreen()
}
