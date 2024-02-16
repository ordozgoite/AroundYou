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
    
    @State private var currentTimeStamp: Int = Int(Date().timeIntervalSince1970)
    
    var activePostsQuantity: Int {
        return feedVM.posts.filter { $0.expirationDate.timeIntervalSince1970InSeconds > currentTimeStamp }.count
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    if feedVM.isLoading {
                        LoadingView()
                    } else {
                        if activePostsQuantity == 0 {
                            EmptyFeed()
                        } else {
                            PostsView()
                        }
                    }
                }
                
                if feedVM.overlayError.0 {
                    AYErrorAlert(message: feedVM.overlayError.1 , isErrorAlertPresented: $feedVM.overlayError.0)
                }
            }
            
            .toolbar {
                ToolbarItem {
                    NavigationLink(destination: NewPostScreen() {
                        Task {
                            try await getFeedInfo()
                        }
                    }.environmentObject(authVM)) {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .navigationTitle("Around You 🌐")
        }
        .onAppear {
            startTimer()
            startUpdatingFeed()
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
                if post.expirationDate.timeIntervalSince1970InSeconds > currentTimeStamp {
                    NavigationLink(destination: CommentScreen(postId: post.id, feedVM: feedVM, post: $post).environmentObject(authVM)) {
                        PostView(feedVM: feedVM, post: $post) {
                            Task {
                                let token = try await authVM.getFirebaseToken()
                                await feedVM.deletePublication(publicationId: post.id, token: token)
                            }
                        }
                        .padding()
                    }
                    .buttonStyle(PlainButtonStyle())
                    Divider()
                }
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
    
    private func startTimer() {
        let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            updateCurrentTime()
        }
        timer.fire()
    }
    
    private func updateCurrentTime() {
        currentTimeStamp = Int(Date().timeIntervalSince1970)
    }
    
    private func getFeedInfo() async throws {
        locationManager.requestLocation()
        if let location = locationManager.location {
            let token = try await authVM.getFirebaseToken()
            print("🔑 USER TOKEN: \(token)")
            
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            
            print("📍 Latitude: \(latitude)")
            print("📍 Longitude: \(longitude)")
            await feedVM.getPostsNearBy(latitude: latitude, longitude: longitude, token: token)
        }
    }
    
    private func startUpdatingFeed() {
        let timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            Task {
                try await updateFeed()
            }
        }
        timer.fire()
    }
    
    private func updateFeed() async throws {
        locationManager.requestLocation()
        if let location = locationManager.location {
            let token = try await authVM.getFirebaseToken()
            
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            
            let response = await AYServices.shared.getActivePublicationsNearBy(latitude: latitude, longitude: longitude, token: token)
            
            switch response {
            case .success(let posts):
                feedVM.posts = posts
            case .failure:
                feedVM.overlayError = (true, ErrorMessage.defaultErrorMessage)
            }
        }
        
        
    }
}

//#Preview {
//    FeedScreen()
//        .environmentObject(AuthenticationViewModel())
//}
