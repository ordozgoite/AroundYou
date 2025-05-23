//
//  ProfileScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import SwiftUI

@MainActor
struct AccountScreen: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var accountVM = AccountViewModel()
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var socket: SocketService
    
    @State private var refreshObserver = NotificationCenter.default
        .publisher(for: .updateUserProfilePosts)
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 32) {
                        ProfileHeader()
                        
                        History()
                    }
                    
                    AYErrorAlert(message: accountVM.overlayError.1, isErrorAlertPresented: $accountVM.overlayError.0)
                }
            }
            .onAppear {
                Task {
                    try await getAllPosts()
                }
            }
            .onReceive(refreshObserver) { _ in
                Task {
                    try await getAllPosts()
                }
            }
            .toolbar {
                ToolbarItem {
                    NavigationLink {
                        SettingsScreen()
                            .environmentObject(authVM)
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            
            NavigationLink(
                destination: EditProfileScreen(),
                isActive: $accountVM.isEditProfileScreenPresented,
                label: { EmptyView() }
            )
        }
    }
    
    //MARK: - Profile Header
    
    @ViewBuilder
    private func ProfileHeader() -> some View {
        VStack(spacing: 16) {
            if let imageURL = authVM.profilePic {
                URLTapableImageView(imageURL: imageURL)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 128, height: 128)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 128, height: 128)
                    .foregroundStyle(.gray)
            }
            
            VStack(spacing: 16) {
                VStack {
                    Text(authVM.name ?? "")
                        .font(.title)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    Text("@\(authVM.username)")
                        .foregroundStyle(.gray)
                        .fontWeight(.semibold)
                        .font(.subheadline)
                }
                
                Text(authVM.biography ?? "")
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .onTapGesture {
            accountVM.isEditProfileScreenPresented = true
        }
    }
    
    //MARK: - History
    
    @ViewBuilder
    private func History() -> some View {
        VStack {
            PostTypeSegmentedControl(selectedFilter: $accountVM.selectedPostType)
            
            PostsView()
        }
    }
    
    //MARK: - Posts View
    
    @ViewBuilder
    private func PostsView() -> some View {
        ScrollView {
            ForEach($accountVM.posts) { $post in
                if shouldDisplay(post: post) {
                    NavigationLink(destination: IndepCommentScreen(postId: post.id, locationManager: locationManager, socket: socket)) {
                        PostView(post: $post, socket: socket, locationManager: locationManager, isClickable: true) {
                            Task {
                                let token = try await authVM.getFirebaseToken()
                                await accountVM.deletePublication(publicationId: post.id, token: token)
                            }
                        } toggleFeedUpdate: { _ in }
                            .padding()
                    }
                    .buttonStyle(PlainButtonStyle())
                    .opacity(post.status == .expired ? 0.5 : 1)
                    
                    Divider()
                }
            }
        }
    }
    
    //MARK: - Auxiliary Methods
    
    private func shouldDisplay(post: FormattedPost) -> Bool {
        switch accountVM.selectedPostType {
        case .all:
            return true
        case .active:
            return post.status == .active
        case .inactive:
            return post.status == .expired
        }
    }
    
    private func getAllPosts() async throws {
        locationManager.requestLocation()
        if let location = locationManager.location {
            let token = try await authVM.getFirebaseToken()
            let currentLocation = Location(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            await accountVM.getUserPosts(location: currentLocation, token: token)
        }
    }
}

#Preview {
    AccountScreen(locationManager: LocationManager(), socket: SocketService())
        .environmentObject(AuthenticationViewModel())
}
