//
//  FeedScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import SwiftUI

struct FeedScreen: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @ObservedObject var feedVM: FeedViewModel
    @StateObject private var communityVM = CommunityViewModel()
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var socket: SocketService
    
    @State private var refreshObserver = NotificationCenter.default
        .publisher(for: .refreshLocationSensitiveData)
    
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
            }
            .toolbar {
                ToolbarItem {
                    NavigationLink(destination: NotificationScreen(location: $locationManager.location, socket: socket).environmentObject(authVM)) {
                        Image(systemName: "bell")
                    }
                }
            }
//            .navigationTitle("Around You")
//            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            startUpdatingFeed()
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
        .frame(maxHeight: .infinity, alignment: .center)
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
        NotificationCenter.default.post(name: .updateLocation, object: nil)
    }
}

//#Preview {
//    FeedScreen()
//        .environmentObject(AuthenticationViewModel())
//}
