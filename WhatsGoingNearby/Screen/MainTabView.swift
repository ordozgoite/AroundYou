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
    @StateObject public var notificationManager = NotificationManager()
    @StateObject private var locationManager = LocationManager()
    
    @State private var isPeopleTabDisplayed: Bool = false
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            FeedScreen(locationManager: locationManager, socket: socket)
                .tabItem {
                    Label("Posts", systemImage: "quote.bubble.fill")
                }
                .environmentObject(authVM)
                .tag(0)
            
            DiscoverScreen(locationManager: locationManager, socket: socket)
                .tabItem {
                    Label("People", systemImage: "heart.fill")
                }
                .environmentObject(authVM)
                .tag(1)
            
            CommunityListScreen(locationManager: locationManager)
                .tabItem {
                    Label("Communities", systemImage: "person.3.fill")
                }
                .environmentObject(authVM)
                .tag(2)
            
            AccountScreen(socket: socket)
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .environmentObject(authVM)
                .tag(3)
        }
        .onChange(of: notificationManager.isPeopleTabDisplayed) { newValue in
            if newValue {
                goToTabPeople()
            }
        }
        .fullScreenCover(isPresented: $notificationManager.isPublicationDisplayed) {
            IndepCommentScreenWrapper(
                postId: notificationManager.publicationId ?? "",
                locationManager: locationManager,
                socket: socket)
        }
        .fullScreenCover(isPresented: $notificationManager.isChatDisplayed) {
            MessageScreenWrapper(
                chatId: notificationManager.chatId ?? "",
                username: notificationManager.username ?? "",
                otherUserUid: notificationManager.senderUserUid ?? "",
                chatPic: notificationManager.chatPic,
                socket: socket)
        }
    }
    
    private func goToTabPeople() {
        selectedTab = 1
    }
}

struct IndepCommentScreenWrapper: View {
    let postId: String
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var socket: SocketService
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            IndepCommentScreen(postId: postId, location: $locationManager.location, socket: socket)
                .navigationBarItems(leading: Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }, label: {
                    Image(systemName: "xmark")
                }))
        }
    }
}

struct MessageScreenWrapper: View {
    let chatId: String
    let username: String
    let otherUserUid: String
    let chatPic: String?
    @ObservedObject var socket: SocketService
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            MessageScreen(
                chatId: chatId,
                username: username,
                otherUserUid: otherUserUid,
                chatPic: chatPic,
                isLocked: false, // TODO: verify if it's really false
                socket: socket)
            .navigationBarItems(leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }, label: {
                Image(systemName: "xmark")
            }))
        }
    }
}
