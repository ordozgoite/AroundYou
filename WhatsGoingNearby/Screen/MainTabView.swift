//
//  MainTabView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import SwiftUI

enum Tab: String {
    case feed
    case chat
    case profile
}

class TabStateHandler: ObservableObject {
    @Published var tabSelected: Tab = .feed {
        didSet {
            print("tabSelected: \(tabSelected)")
            if oldValue == tabSelected && tabSelected == .feed {
                print("Entrou na aba")
//                scrollToTop()
            }
        }
    }
    
//    private func scrollToTop() {
//        let name = Notification.Name(Constants.scrollToTopNotificationKey)
//        NotificationCenter.default.post(name: name, object: nil)
//    }
    
}

struct MainTabView: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject var tabStateHandler: TabStateHandler = TabStateHandler()
    
    var body: some View {
        TabView {
            FeedScreen()
                .tabItem {
                    Label("Around You", systemImage: "mappin.and.ellipse")
                }
                .environmentObject(authVM)
                .tag(Tab.feed)
            
            ChatListScreen()
                .tabItem {
                    Label("Chats", systemImage: "bubble.left.and.bubble.right")
                }
                .environmentObject(authVM)
                .tag(Tab.chat)
            
            AccountScreen()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .environmentObject(authVM)
                .tag(Tab.profile)
        }
    }
}
