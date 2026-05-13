//
//  ClusterPostsScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 12/05/26.
//

import SwiftUI

struct ClusterPostsScreen: View {
    let bounds: MapClusterBounds
    
    @StateObject private var viewModel = ClusterPostsViewModel()
    @EnvironmentObject var authVM: AuthenticationViewModel
    @EnvironmentObject var locationManager: LocationManager
    
    var body: some View {
        ZStack {
            if viewModel.isLoading {
                ProgressView()
            } else {
                PostsView()
            }
        }
        .onAppear {
            loadScreen()
        }
        .navigationTitle("Posts")
    }
    
    //MARK: - Feed
    
    @ViewBuilder
    private func PostsView() -> some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    Posts(ofType: .active)
                    
                    if hasInactivePublication() {
                        Text("Expired")
                            .font(.title3)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                    
                    Posts(ofType: .expired)
                        .opacity(0.5)
                }
            }
            .background(Color.clear)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    //MARK: - Posts
    
    @ViewBuilder
    private func Posts(ofType postType: PostStatus) -> some View {
        ForEach($viewModel.posts) { $post in
            if post.status == postType {
                PostView(post: post, isClickable: true)
                    .padding()
                
                Divider()
            }
        }
    }
}

// MARK: - Private Methods

extension ClusterPostsScreen {
    private func loadScreen() {
        Task {
            do {
                viewModel.isLoading = true
                defer { viewModel.isLoading = false }
                let token = try await authVM.getFirebaseToken()
                let location = try getCurrentLocation()
                await viewModel.fetchPosts(forBounds: bounds, withLocation: location, withToken: token)
            } catch {
                // TODO: display error
            }
        }
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
    
    private func hasInactivePublication() -> Bool {
        for publication in viewModel.posts {
            if publication.status == .expired {
                return true
            }
        }
        return false
    }
}

//#Preview {
//    ClusterPostsScreen()
//}
