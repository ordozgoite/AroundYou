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
    @ObservedObject var locationManager = LocationManager()
    @ObservedObject public var notificationManager = NotificationManager()
    
    @State private var refreshObserver = NotificationCenter.default
        .publisher(for: NSNotification.Name(Constants.refreshFeedNotificationKey))
    
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
                
                Navigation()
            }
            
            .toolbar {
                ToolbarItem {
                    NavigationLink(destination: NotificationScreen(location: $locationManager.location).environmentObject(authVM)) {
                        Image(systemName: "bell")
                    }
                }
            }
            .navigationTitle("Around You")
            .navigationBarTitleDisplayMode(.large)
        }
        .onReceive(refreshObserver) { _ in
            Task {
                try await getNearByPosts()
            }
        }
        .onAppear {
            startUpdatingFeed()
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
        EmptyFeedView()
            .environmentObject(authVM)
    }
    
    //MARK: - Feed
    
    @ViewBuilder
    private func Feed() -> some View {
        ScrollView {
            VStack {
                NewPostView()
                    .environmentObject(authVM)
                
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
                NavigationLink(destination: CommentScreen(postId: post.id, post: $post, location: $locationManager.location).environmentObject(authVM)) {
                    PostView(post: $post, location: $locationManager.location, deletePost: {
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
    
    @ViewBuilder
    private func Navigation() -> some View {
        NavigationLink(
            destination: IndepCommentScreen(postId: notificationManager.publicationId ?? "", location: $locationManager.location),
            isActive: $notificationManager.isPublicationDisplayed,
            label: { EmptyView() }
        )
        
        NavigationLink(
            destination: MessageScreen(chatId: notificationManager.chatId ?? "", username: notificationManager.username ?? "", otherUserUid: notificationManager.senderUserUid ?? "", chatPic: notificationManager.chatPic),
            isActive: $notificationManager.isChatDisplayed,
            label: { EmptyView() }
        )
    }
    
    //MARK: - Private Method
    
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
        let name = Notification.Name(Constants.updateLocationNotificationKey)
        NotificationCenter.default.post(name: name, object: nil)
    }
}

//#Preview {
//    FeedScreen()
//        .environmentObject(AuthenticationViewModel())
//}
