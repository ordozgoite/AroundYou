//
//  MainTabView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import SwiftUI

struct MainTabView: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    
    @State private var tabSelection = 1
    
    var handler: Binding<Int> { Binding(
        get: { self.tabSelection },
        set: {
            if $0 == self.tabSelection {
                scrollToTop()
            }
            self.tabSelection = $0
        }
    )}
    
    var body: some View {
        TabView(selection: handler) {
            FeedScreen()
                .tabItem {
                    Label("Around You", systemImage: "mappin.and.ellipse")
                }
                .environmentObject(authVM)
                .id(1)
            
            ChatListScreen()
                .tabItem {
                    Label("Chats", systemImage: "bubble.left.and.bubble.right")
                }
                .environmentObject(authVM)
                .id(2)
            
            AccountScreen()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .environmentObject(authVM)
                .id(3)
        }
    }
    
    //MARK: - Private Method
    
    private func scrollToTop() {
        let name = Notification.Name(Constants.scrollToTopNotificationKey)
        NotificationCenter.default.post(name: name, object: nil)
    }
}
