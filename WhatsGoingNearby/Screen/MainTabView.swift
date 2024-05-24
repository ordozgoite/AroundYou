//
//  MainTabView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import SwiftUI

struct MainTabView: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    let persistenceController = PersistenceController.shared
    
    @State private var badgeTimer: Timer?
    @State private var unreadChats: Int?
    
    var body: some View {
        TabView {
            FeedScreen()
                .tabItem {
                    Label("Around You", systemImage: "mappin.and.ellipse")
                }
                .environmentObject(authVM)
            
            ChatListScreen()
                .tabItem {
                    Label("Chats", systemImage: "bubble.left.and.bubble.right")
                }
                .environmentObject(authVM)
                .badge(unreadChats ?? 0)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
            
            AccountScreen()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .environmentObject(authVM)
        }
        .onAppear {
            startUpdatingBadge()
        }
    }
    
    //MARK: - Private Method
    
    private func startUpdatingBadge() {
        badgeTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task {
                self.unreadChats = try await getChatBadge()
            }
        }
        badgeTimer?.fire()
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
