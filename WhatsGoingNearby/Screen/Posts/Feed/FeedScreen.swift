//
//  FeedScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import SwiftUI

struct FeedScreen: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var feedVM = FeedViewModel()
    @StateObject private var communityVM = CommunityViewModel()
    @ObservedObject var locationManager: LocationManager
//    @StateObject public var notificationManager = NotificationManager()
    @ObservedObject var socket: SocketService
    
    @State private var refreshObserver = NotificationCenter.default
        .publisher(for: .refreshLocationSensitiveData)
    
    let pub = NotificationCenter.default
        .publisher(for:.updateBadge)

    @State private var badgeTimer: Timer?
    @State private var unreadChats: Int = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    if !locationManager.isLocationAuthorized {
                        EnableLocationView()
                    } else if !locationManager.isUsingFullAccuracy {
                        EnableFullAccuracyView()
                    } else if feedVM.isLoading {
                        LoadingView()
                    } else if feedVM.initialPostsFetched {
                        if feedVM.posts.isEmpty {
                            EmptyFeed()
                        } else {
                            Feed()
                        }
                    }
                }
                
                AYErrorAlert(message: feedVM.overlayError.1 , isErrorAlertPresented: $feedVM.overlayError.0)
                
//                Navigation()
            }
            .toolbar {
                ToolbarItem {
                    NavigationLink(destination: NotificationScreen(location: $locationManager.location, socket: socket).environmentObject(authVM)) {
                        Image(systemName: "bell")
                    }
                }
                
                ToolbarItem {
                    NavigationLink(destination: ChatListScreen(socket: socket).environmentObject(authVM)) {
                        Image(systemName: "bubble")
                    }
                    .overlay(CustomBadge(count: unreadChats))
                }
            }
            .navigationTitle("Around You")
            .navigationBarTitleDisplayMode(.large)
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
            startUpdatingFeed()
            updateBadge()
            listenToMessages()
        }
        .onReceive(refreshObserver) { _ in
            Task {
                try await getNearByPosts()
            }
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    //MARK: - Loading
    
    @ViewBuilder
    private func LoadingView() -> some View {
        VStack {
            AYProgressView()
            
            Text("Looking around you...")
                .foregroundStyle(.gray)
                .fontWeight(.semibold)
        }
    }
    
    //MARK: - Empty Feed
    
    @ViewBuilder
    private func EmptyFeed() -> some View {
        EmptyFeedView(communityVM: communityVM, locationManager: locationManager)
            .environmentObject(authVM)
    }
    
    //MARK: - Feed
    
    @ViewBuilder
    private func Feed() -> some View {
        ScrollView {
            VStack {
                NewPostView()
                    .environmentObject(authVM)
                
//                CommunitySuggestionView(locationManager: locationManager)
//                    .environmentObject(authVM)
                
                Posts(ofType: .active)
                
                if hasInactivePublication() {
                    Text("Expired")
                        .font(.title3)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                        .padding()
                }
                
                Posts(ofType: .inactive)
                    .opacity(0.5)
            }
        }
        .refreshable {
            hapticFeedback(style: .soft)
            updateLocation()
        }
    }
    
    //MARK: - Posts
    
    @ViewBuilder
    private func Posts(ofType postType: PostType) -> some View {
        ForEach($feedVM.posts) { $post in
            if post.type == postType {
                NavigationLink(destination: CommentScreen(postId: post.id, post: $post, location: $locationManager.location, socket: socket).environmentObject(authVM)) {
                    PostView(post: $post, location: $locationManager.location, socket: socket, deletePost: {
                        Task {
                            let token = try await authVM.getFirebaseToken()
                            await feedVM.deletePublication(publicationId: post.id, token: token)
                        }
                    }) { shouldUpdate in
                        feedVM.shouldUpdateFeed = shouldUpdate
                    }
                    .padding()
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
            }
        }
    }
    
    //MARK: - Navigation
    
//    @ViewBuilder
//    private func Navigation() -> some View {
//        NavigationLink(
//            destination: IndepCommentScreen(postId: notificationManager.publicationId ?? "", location: $locationManager.location, socket: socket),
//            isActive: $notificationManager.isPublicationDisplayed,
//            label: { EmptyView() }
//        )
//        
//        NavigationLink(
//            destination: MessageScreen(
//                chatId: notificationManager.chatId ?? "",
//                username: notificationManager.username ?? "",
//                otherUserUid: notificationManager.senderUserUid ?? "",
//                chatPic: notificationManager.chatPic,
//                socket: socket),
//            isActive: $notificationManager.isChatDisplayed,
//            label: { EmptyView() }
//        )
//    }
    
    //MARK: - Private Method
    
    private func updateBadge() {
        Task {
            self.unreadChats = try await getChatBadge() ?? 0
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
    
    private func startUpdatingFeed() {
        feedVM.feedTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task {
                try await getNearByPosts()
            }
        }
        feedVM.feedTimer?.fire()
    }
    
    private func getNearByPosts() async throws {
        locationManager.requestLocation()
        if let location = locationManager.location {
            let token = try await authVM.getFirebaseToken()
            
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            
            await feedVM.getPosts(latitude: latitude, longitude: longitude, token: token)
        }
    }
    
    private func stopTimer() {
        feedVM.feedTimer?.invalidate()
    }
    
    private func hasInactivePublication() -> Bool {
        for publication in feedVM.posts {
            if publication.type == .inactive {
                return true
            }
        }
        return false
    }
    
    private func updateLocation() {
        NotificationCenter.default.post(name: .updateLocation, object: nil)
    }
}

//#Preview {
//    FeedScreen()
//        .environmentObject(AuthenticationViewModel())
//}
