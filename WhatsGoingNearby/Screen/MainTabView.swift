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
                    Image(systemName: "globe")
                    Text("Around You")
                }
                .environmentObject(authVM)
            
            ChatListScreen()
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right")
                    Text("Messages")
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
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .environmentObject(authVM)
        }
    }
}
