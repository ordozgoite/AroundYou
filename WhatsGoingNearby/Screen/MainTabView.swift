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
                    Image(systemName: "location.fill")
                    Text("Around you")
                }
                .environmentObject(authVM)
            
            ProfileScreen()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .environmentObject(authVM)
        }
    }
}

#Preview {
    MainTabView()
}
