//
//  MainTabView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            FeedScreen()
                .tabItem {
                    Image(systemName: "location.fill")
                    Text("Around you")
                }
            
            ProfileScreen()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
        }
    }
}

#Preview {
    MainTabView()
}
