//
//  FeedScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import SwiftUI

struct PlacesScreen: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @ObservedObject var placesVM: PlacesViewModel
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
                    } else if placesVM.isLoading {
                        LoadingView()
                    } else if placesVM.initialPostsFetched {
                        if placesVM.posts.isEmpty {
                            EmptyFeed()
                        } else {
                            Feed()
                        }
                    }
                }
                
                AYErrorAlert(message: placesVM.overlayError.1 , isErrorAlertPresented: $placesVM.overlayError.0)
            }
            .toolbar {
                ToolbarItem {
                    Urgent()
                }
                
                ToolbarItem {
                    NavigationLink(destination: NotificationScreen(location: $locationManager.location, socket: socket).environmentObject(authVM)) {
                        Image(systemName: "bell")
                    }
                }
            }
//            .navigationTitle("Around You")
//            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $placesVM.isHelpViewDisplayed) {
            HelpView()
                .environmentObject(authVM)
        }
        .sheet(isPresented: $placesVM.isLostAndFoundScreenDisplayed) {
            LostAndFoundView(isViewDisplayed: $placesVM.isLostAndFoundScreenDisplayed)
                .environmentObject(authVM)
        }
        .interactiveDismissDisabled(true)
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
        ForEach($placesVM.posts) { $post in
            if post.type == postType {
                NavigationLink(destination: CommentScreen(postId: post.id, post: $post, location: $locationManager.location, socket: socket).environmentObject(authVM)) {
                    PostView(post: $post, location: $locationManager.location, socket: socket, deletePost: {
                        Task {
                            let token = try await authVM.getFirebaseToken()
                            await placesVM.deletePublication(publicationId: post.id, token: token)
                        }
                    }) { shouldUpdate in
                        placesVM.shouldUpdateFeed = shouldUpdate
                    }
                    .padding()
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
            }
        }
    }
    
    // MARK: - Urgent
    
    @ViewBuilder
    private func Urgent() -> some View {
        Menu {
            Button {
                placesVM.isLostAndFoundScreenDisplayed = true
            } label: {
                Label("I Lost Something", systemImage: "hand.raised")
            }
            
            Button {
                placesVM.isReportScreenDisplayed = true
            } label: {
                Label("Report", systemImage: "megaphone")
            }
            
            Button {
                placesVM.isHelpViewDisplayed = true
            } label: {
                Label("Help!", systemImage: "light.beacon.max")
            }
        } label: {
            Image(systemName: "light.beacon.max")
        }

    }
    
    //MARK: - Private Method
    
    private func startUpdatingFeed() {
        placesVM.feedTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task {
                try await getNearByPosts()
            }
        }
        placesVM.feedTimer?.fire()
    }
    
    private func getNearByPosts() async throws {
        locationManager.requestLocation()
        if let location = locationManager.location {
            let token = try await authVM.getFirebaseToken()
            
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            
            await placesVM.getPosts(latitude: latitude, longitude: longitude, token: token)
        }
    }
    
    private func stopTimer() {
        placesVM.feedTimer?.invalidate()
    }
    
    private func hasInactivePublication() -> Bool {
        for publication in placesVM.posts {
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
