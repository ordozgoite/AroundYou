//
//  MainTabView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import SwiftUI

struct MainTabView: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    
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
            
//            MapScreen()
//                .tabItem {
//                    Image(systemName: "mappin.and.ellipse")
//                    Text("Map")
//                }
//                .environmentObject(authVM)
            
            AccountScreen()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .environmentObject(authVM)
        }
    }
}
