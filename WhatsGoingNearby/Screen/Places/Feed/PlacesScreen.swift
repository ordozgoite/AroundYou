//
//  FeedScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import SwiftUI

private struct PublicationBoundsPreferenceValue {
    let bounds: Anchor<CGRect>
    let isAuthor: Bool
}

private struct PublicationBoundsPreferenceKey: PreferenceKey {
    static var defaultValue: [String: PublicationBoundsPreferenceValue] = [:]

    static func reduce(
        value: inout [String: PublicationBoundsPreferenceValue],
        nextValue: () -> [String: PublicationBoundsPreferenceValue]
    ) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

struct PlacesScreen: View, PostViewActionHandler {
    @EnvironmentObject var authVM: AuthenticationViewModel
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var navCoordinator: NavigationCoordinator
    @EnvironmentObject var socket: SocketService
    @EnvironmentObject var placesVM: PlacesViewModel
    @State private var refreshObserver = NotificationCenter.default
        .publisher(for: .refreshLocationSensitiveData)
    
    var body: some View {
        ZStack {
            if placesVM.initialPostsFetched && placesVM.posts.isEmpty {
                EmptyFeedBackground()
            }
            
            VStack {
                if !locationManager.isLocationAuthorized {
                    EnableLocationView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !locationManager.isUsingFullAccuracy {
                    EnableFullAccuracyView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if placesVM.isLoading {
                    LoadingView()
                } else if placesVM.initialPostsFetched {
                    Feed()
                }
            }
            
            if isFeedDisplayed {
                CreatePostFloatingButton {
                    navCoordinator.navigate(to: .createPost)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.trailing, 20)
                .padding(.bottom, 16)
            }

            AYErrorAlert(message: placesVM.overlayError.1 , isErrorAlertPresented: $placesVM.overlayError.0)
        }
        .toolbar {
            ToolbarItem { Urgent() }
            
            if #available(iOS 26.0, *) {
                ToolbarSpacer(.fixed)
            }
            
            ToolbarItem { Notifications() }
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
            Task {
                try await getNearByPosts()
                startUpdatingFeed()
            }
        }
        .onReceive(refreshObserver) { _ in
            Task {
                try await getNearByPosts()
            }
        }
        .onDisappear {
            stopTimer()
            FeedVideoPlaybackCoordinator.shared.resetMutePreference()
            PublicationViewTracker.shared.flushWhenLeavingFeed()
        }
    }
    
    //MARK: - Loading
    
    @ViewBuilder
    private func LoadingView() -> some View {
        VStack {
            AYProgressView()
            
            Text("Looking around you...")
                .foregroundStyle(.secondary)
                .fontWeight(.semibold)
        }
        .frame(maxHeight: .infinity, alignment: .center)
    }
    
    //MARK: - Empty Feed
    
    //    @ViewBuilder
    //    private func EmptyFeed() -> some View {
    //        EmptyFeedView {
    //            Task {
    //                placesVM.initialPostsFetched = false
    //                try await getNearByPosts()
    //            }
    //        }
    //    }
    
    //MARK: - Feed
    
    @ViewBuilder
    private func Feed() -> some View {
        ZStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ExploreMapCard {
                        navCoordinator.navigate(to: .exploreMap)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)

                    PendingPostSection()

                    if !placesVM.posts.isEmpty && !hasActivePublication() {
                        NoActivePostsView()
                    }

                    if !placesVM.posts.isEmpty {
                        PostsContent()
                    }
                }
                // Keeps the last publication reachable above the floating button.
                .padding(.bottom, 80)
            }
            .backgroundPreferenceValue(PublicationBoundsPreferenceKey.self) { publications in
                GeometryReader { proxy in
                    let viewport = CGRect(origin: .zero, size: proxy.size)
                    let candidates = publications.map { publicationId, value in
                        let frame = proxy[value.bounds]
                        let visibleHeight = frame.intersection(viewport).height
                        let requiredHeight = min(frame.height * 0.5, viewport.height * 0.35)
                        return PublicationVisibilityCandidate(
                            publicationId: publicationId,
                            isAuthor: value.isAuthor,
                            isSufficientlyVisible: frame.height > 0 && visibleHeight >= requiredHeight
                        )
                    }.sorted { $0.publicationId < $1.publicationId }
                    Color.clear
                        .allowsHitTesting(false)
                        .onAppear {
                            PublicationViewTracker.shared.updateVisiblePublications(candidates)
                        }
                        .onChange(of: candidates) {
                            PublicationViewTracker.shared.updateVisiblePublications($0)
                        }
                }
            }
            .background(Color.clear)
            .refreshable {
                do {
                    try await getNearByPosts()
                } catch {
                    print("❌ Error trying to refresh posts.")
                }
            }

            if placesVM.posts.isEmpty {
                EmptyFeedMessage {
                    Task {
                        placesVM.initialPostsFetched = false
                        try await getNearByPosts()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    //MARK: - Pending Post
    
    @ViewBuilder
    private func PendingPostSection() -> some View {
        if let _ = placesVM.postToBePublished {
            PendingPostUploadView(
                post: Binding(
                    get: { placesVM.postToBePublished! },
                    set: { placesVM.postToBePublished = $0 }
                ),
                onRetry: {
                    Task {
                        placesVM.postToBePublished?.progress = 0
                        placesVM.postToBePublished?.status = .queued
                        await startCreatingPendingPost()
                    }
                },
                onCancel: {
                    placesVM.cancelCreatingPendingPost()
                }
            )
            .padding()
            .onAppear {
                Task {
                    await startCreatingPendingPost()
                }
            }
        }
    }
    
    //MARK: - Posts Content
    
    @ViewBuilder
    private func PostsContent() -> some View {
        Posts(ofType: .active)
        
        if hasInactivePublication() {
            HStack(spacing: 6) {
                Image(systemName: "clock")

                Text("Expired Posts")
            }
            .font(.title3)
            .fontWeight(.bold)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        
        Posts(ofType: .expired)
            .opacity(0.5)
    }
    
    //MARK: - Posts
    
    @ViewBuilder
    private func Posts(ofType postType: PostStatus) -> some View {
        ForEach($placesVM.posts) { $post in
            if post.status == postType {
                PostView(post: post, delegate: self, isClickable: true)
                    .padding()
                    .anchorPreference(key: PublicationBoundsPreferenceKey.self, value: .bounds) {
                        [post.id: PublicationBoundsPreferenceValue(bounds: $0, isAuthor: post.isFromRecipientUser)]
                    }
                
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
    
    //MARK: - Feed Availability

    /// The floating button follows the same conditions as the feed itself, so it
    /// only shows up when creating a publication is actually possible.
    private var isFeedDisplayed: Bool {
        locationManager.isLocationAuthorized
        && locationManager.isUsingFullAccuracy
        && !placesVM.isLoading
        && placesVM.initialPostsFetched
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
        do {
            try await attemptToGetPosts()
        } catch {
            print("❌ Error trying to get posts nearby.")
        }
    }
    
    private func startCreatingPendingPost() async {
        do {
            let currentLocation = try getCurrentLocation()
            let token = try await authVM.getFirebaseToken()
            
            placesVM.startCreatingPendingPost(
                latitude: currentLocation.latitude,
                longitude: currentLocation.longitude,
                token: token
            )
        } catch {
            placesVM.postToBePublished?.status = .failed(message: "Erro ao preparar publicação")
        }
    }
    
    private func attemptToGetPosts() async throws {
        let currentLocation = try getCurrentLocation()
        let token = try await authVM.getFirebaseToken()
        await placesVM.getPosts(location: currentLocation, token: token)
    }
    
    private func getCurrentLocation() throws -> Location {
        locationManager.requestLocation()
        if let location = locationManager.location {
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            return Location(latitude: latitude, longitude: longitude)
        } else {
            throw LocationError.unableToGetCurrentLocation
        }
    }
    
    private func stopTimer() {
        placesVM.feedTimer?.invalidate()
    }
    
    private func hasActivePublication() -> Bool {
        for publication in placesVM.posts {
            if publication.status == .active {
                return true
            }
        }
        return false
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
//    PlacesScreen(placesVM: PlacesViewModel())
//        .environmentObject(AuthenticationViewModel())
//        .environmentObject(LocationManager())
//        .environmentObject(NavigationCoordinator())
//}
