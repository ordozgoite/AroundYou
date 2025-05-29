//
//  FeedScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import SwiftUI

struct PlacesScreen: View, PostViewActionHandler {
    @EnvironmentObject var authVM: AuthenticationViewModel
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var navCoordinator: NavigationCoordinator
    @EnvironmentObject var socket: SocketService
    @ObservedObject var placesVM: PlacesViewModel
    @State private var refreshObserver = NotificationCenter.default
        .publisher(for: .refreshLocationSensitiveData)
    
    var body: some View {
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
                Notifications()
            }
        }
        .sheet(isPresented: $placesVM.isHelpViewDisplayed) {
            HelpView()
                .environmentObject(authVM)
        }
        .sheet(isPresented: $placesVM.isLostAndFoundScreenDisplayed) {
            LostAndFoundView(isViewDisplayed: $placesVM.isLostAndFoundScreenDisplayed)
                .environmentObject(authVM)
                .interactiveDismissDisabled(true)
        }
        .sheet(isPresented: $placesVM.isReportScreenDisplayed) {
            ReportIncidentView(isViewDisplayed: $placesVM.isReportScreenDisplayed)
                .environmentObject(authVM)
                .interactiveDismissDisabled(true)
        }
        
        .onAppear {
            startUpdatingFeed()
        }
        .onReceive(refreshObserver) { _ in
            getNearByPosts()
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
        EmptyFeedView()
            .environmentObject(authVM)
    }
    
    //MARK: - Feed
    
    @ViewBuilder
    private func Feed() -> some View {
        ScrollView {
            VStack {
                NewPostView()
                    .onTapGesture {
                        navCoordinator.navigate(to: .createPost)
                    }
                
                Posts(ofType: .active)
                
                if hasInactivePublication() {
                    Text("Expired")
                        .font(.title3)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                        .padding()
                }
                
                Posts(ofType: .expired)
                    .opacity(0.5)
            }
        }
        .refreshable {
            hapticFeedback(style: .soft)
            placesVM.initialPostsFetched = false
            getNearByPosts()
        }
    }
    
    //MARK: - Posts
    
    @ViewBuilder
    private func Posts(ofType postType: PostStatus) -> some View {
        ForEach($placesVM.posts) { $post in
            if post.status == postType {
                PostView(post: post, delegate: self, isClickable: true)
                    .padding()
                
                Divider()
            }
        }
    }
    
    // MARK: - Notifications
    
    @ViewBuilder
    private func Notifications() -> some View {
        NavigationLink(destination: NotificationScreen(location: $locationManager.location)) {
            Image(systemName: "bell")
        }
    }
    
    // MARK: - Urgent
    
    @ViewBuilder
    private func Urgent() -> some View {
        Menu {
            Button {
                placesVM.isLostAndFoundScreenDisplayed = true
            } label: {
                Label("I Lost Something", systemImage: "magnifyingglass")
            }
            
            Button {
                placesVM.isReportScreenDisplayed = true
            } label: {
                Label("Report an Incident", systemImage: "exclamationmark.bubble")
            }
            
            Button {
                placesVM.isHelpViewDisplayed = true
            } label: {
                Label("Help!", systemImage: "sos")
            }
        } label: {
            Image(systemName: "light.beacon.max")
        }
        
    }
    
    //MARK: - Private Method
    
    private func startUpdatingFeed() {
        placesVM.feedTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            getNearByPosts()
        }
        placesVM.feedTimer?.fire()
    }
    
    private func getNearByPosts() {
        Task {
            do {
                try await attemptToGetPosts()
            } catch {
                print("❌ Error trying to get posts nearby.")
            }
            
        }
    }
    
    private func attemptToGetPosts() async throws {
        let currentLocation = try getCurrentLocation()
        let token = try await authVM.getFirebaseToken()
        await placesVM.getPosts(latitude: currentLocation.latitude, longitude: currentLocation.longitude, token: token)
    }
    
    private func getCurrentLocation() throws -> Location {
        locationManager.requestLocation()
        if let location = locationManager.location {
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            return Location(latitude: latitude, longitude: longitude)
        } else {
            placesVM.overlayError = (true, ErrorMessage.locationDisabledErrorMessage)
            throw LocationError.unableToGetCurrentLocation
        }
    }
    
    private func stopTimer() {
        placesVM.feedTimer?.invalidate()
    }
    
    private func hasInactivePublication() -> Bool {
        for publication in placesVM.posts {
            if publication.status == .expired {
                return true
            }
        }
        return false
    }
    
    private func updateLocation() {
        NotificationCenter.default.post(name: .updateLocation, object: nil)
    }
}

// MARK: - Post View Protocol

extension PlacesScreen {
    func postViewDidLikePublication(_ content: FormattedPost) {
        placesVM.likePost(withId: content.id)
    }
    
    func postViewDidUnlikePublication(_ content: FormattedPost) {
        placesVM.unlikePost(withId: content.id)
    }
    
    func postViewDidDeletePublication(_ content: FormattedPost) {
        placesVM.removePost(withId: content.id)
    }
    
    func postViewDidDeleteLostItem(_ content: FormattedPost) {
        placesVM.removePost(withId: content.id)
    }
    
    func postViewDidDeleteReport(_ content: FormattedPost) {
        placesVM.removePost(withId: content.id)
    }
    
    func postViewDidFollow(_ content: FormattedPost) {
        placesVM.followPost(withId: content.id)
    }
    
    func postViewDidUnfollow(_ content: FormattedPost) {
        placesVM.unfollowPost(withId: content.id)
    }
    
    func postViewDidMarkAsCompleted(_ content: FormattedPost) {
        placesVM.finishPost(withId: content.id)
    }
}

//#Preview {
//    FeedScreen()
//        .environmentObject(AuthenticationViewModel())
//}
