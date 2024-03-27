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
                    } else {
                        if feedVM.isLoading {
                            LoadingView()
                        } else {
                            FeedTypeSegmentedControl(selectedFilter: $feedVM.selectedFeed)
                            
                            Posts()
                        }
                    }
                }
                
                AYErrorAlert(message: feedVM.overlayError.1 , isErrorAlertPresented: $feedVM.overlayError.0)
                
                NavigationLink(
                    destination: PostScreen(postId: notificationManagaer.id ?? "", location: $locationManager.location),
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
                
                ToolbarItem {
                    NavigationLink(destination: NewPostScreen() {
                        Task {
                            try await getNearByPosts()
                        }
                    }.environmentObject(authVM)) {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .navigationTitle("Around You 🌐")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            startUpdatingTime()
            startUpdatingFeed()
        }
        .onChange(of: feedVM.selectedFeed) { type in
            changeFeedTo(type)
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
    
    //MARK: - Posts
    
    @ViewBuilder
    private func Posts() -> some View {
        ScrollView {
            ForEach($feedVM.posts) { $post in
                if displayPost(withExpiration: post.expirationDate) {
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
    }
    
    //MARK: - Auxiliary Method
    
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
    
    private func changeFeedTo(_ type: FeedType) {
        stopTimers()
        startUpdatingTime()
        startUpdatingFeed()
    }
    
    private func displayPost(withExpiration expirationDate: Int) -> Bool {
        switch feedVM.selectedFeed {
        case .old:
            return expirationDate.timeIntervalSince1970InSeconds <= feedVM.currentTimeStamp
        case .now:
            return expirationDate.timeIntervalSince1970InSeconds > feedVM.currentTimeStamp
        }
    }
}

//#Preview {
//    FeedScreen()
//        .environmentObject(AuthenticationViewModel())
//}
