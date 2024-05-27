//
//  MainTabView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import SwiftUI

struct MainTabView: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var socket = SocketService()
    let persistenceController = PersistenceController.shared
    let pub = NotificationCenter.default
        .publisher(for: NSNotification.Name(Constants.updateBadgeNotificationKey))
    
    @State private var badgeTimer: Timer?
    @State private var unreadChats: Int?
    
    var body: some View {
        TabView {
            FeedScreen(socket: socket)
                .tabItem {
                    Label("Around You", systemImage: "mappin.and.ellipse")
                }
                .environmentObject(authVM)
            
            ChatListScreen(socket: socket)
                .tabItem {
                    Label("Chats", systemImage: "bubble.left.and.bubble.right")
                }
                .environmentObject(authVM)
                .badge(unreadChats ?? 0)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
            
            AccountScreen(socket: socket)
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .environmentObject(authVM)
        }
        .onChange(of: socket.status) { status in
            if status == .connected {
                updateBadge()
            }
        }
        .onReceive(pub) { (output) in
            self.updateBadge()
        }
        .onAppear {
            updateBadge()
            listenToMessages()
        }
    }
    
    //MARK: - Private Method
    
    private func updateBadge() {
        Task {
            self.unreadChats = try await getChatBadge()
        }
    }
    
    private func listenToMessages() {
        socket.socket?.on("badge") { data, ack in
            updateBadge()
        }
    }
    
    private func getChatBadge() async throws -> Int? {
        let token = try await authVM.getFirebaseToken()
        let result = await AYServices.shared.getUnreadChatsNumber(token: token)
        
        switch result {
        case .success(let response):
            return response.quantity
        case .failure:
            print("❌ Error trying to get unread messages number.")
        }
        return nil
    }
}
