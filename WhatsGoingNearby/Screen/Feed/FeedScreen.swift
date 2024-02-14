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
    
    var body: some View {
        NavigationStack {
            VStack {
                if feedVM.isLoading {
                    LoadingView()
                } else {
                    if feedVM.posts.isEmpty {
                        EmptyFeed()
                    } else {
                        PostsView()
                    }
                }
            }
            
            .toolbar {
                ToolbarItem {
                    NavigationLink(destination: NewPostScreen()) {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .navigationTitle("Around You 🌐")
        }
        .onAppear {
            Task {
                try await getFeedInfo()
            }
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
    
    //MARK: - Posts View
    
    @ViewBuilder
    private func PostsView() -> some View {
        ScrollView {
            ForEach($feedVM.posts) { $post in
                PostView(feedVM: feedVM, post: $post)
                    .padding()
            }
        }
        .refreshable {
            Task {
                try await getFeedInfo()
            }
        }
    }
    
    //MARK: - Empty Feed
    
    @ViewBuilder
    private func EmptyFeed() -> some View {
        VStack {
            Text("There are no posts around you")
                .foregroundStyle(.gray)
                .fontWeight(.semibold)
            
            Image(systemName: "arrow.clockwise")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
                .foregroundStyle(.gray)
                .onTapGesture {
                    print("👉 Refresh!")
                    Task {
                        try await getFeedInfo()
                    }
                }
        }
    }
    
    //MARK: - Auxiliary Method
    
    private func getFeedInfo() async throws {
        locationManager.requestLocation()
        if let location = locationManager.location {
            let token = try await authVM.getFirebaseToken()
            print("🔑 USER TOKEN: \(token)")
            
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            
            print("📍 Latitude: \(latitude)")
            print("📍 Longitude: \(longitude)")
            
            
            locationManager.requestLocation()
            await feedVM.getPostsNearBy(latitude: latitude, longitude: longitude, token: token)
        }
    }
}

#Preview {
    FeedScreen()
}
