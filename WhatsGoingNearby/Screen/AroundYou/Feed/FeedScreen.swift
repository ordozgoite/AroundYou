//
//  FeedScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import SwiftUI

struct FeedScreen: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @ObservedObject private var feedVM = FeedViewModel()
    @ObservedObject var locationManager = LocationManager()
    @ObservedObject public var notificationManagaer = NotificationManager()
    
    var activePostsQuantity: Int {
        return feedVM.posts.filter { $0.expirationDate.timeIntervalSince1970InSeconds > feedVM.currentTimeStamp }.count
    }
    
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
                
                NavigationLink(
                    destination: IndepCommentScreen(postId: notificationManagaer.id ?? "", location: $locationManager.location),
                    isActive: $notificationManagaer.isPublicationDisplayed,
                    label: { EmptyView() }
                )
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
        .onAppear {
            startUpdatingTime()
            startUpdatingFeed()
        }
        .onDisappear {
            stopTimers()
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
        EmptyFeedView() {
            Task {
                try await getNearByPosts()
            }
        }.environmentObject(authVM)
    }
    
    //MARK: - Feed
    
    @ViewBuilder
    private func Feed() -> some View {
        ScrollView {
            ScrollViewReader { proxy in
                VStack {
                    NewPostView() {
                        Task {
                            try await getNearByPosts()
                        }
                    }.environmentObject(authVM)
                    
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
                .onChange(of: feedVM.isTabBarDoubleClicked) { _ in
                    withAnimation {
                        proxy.scrollTo(feedVM.posts.first!.id, anchor: .bottom)
                    }
                }
            }
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
    
    //MARK: - Private Method
    
    private func startUpdatingTime() {
        feedVM.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            updateCurrentTime()
        }
        feedVM.timer?.fire()
    }
    
    private func updateCurrentTime() {
        feedVM.currentTimeStamp = Int(Date().timeIntervalSince1970)
    }
    
    private func startUpdatingFeed() {
        feedVM.feedTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
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
    
    private func stopTimers() {
        feedVM.timer?.invalidate()
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
}

//#Preview {
//    FeedScreen()
//        .environmentObject(AuthenticationViewModel())
//}
