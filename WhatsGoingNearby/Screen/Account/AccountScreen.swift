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
    @ObservedObject private var accountVM = AccountViewModel()
    @ObservedObject var locationManager = LocationManager()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    ProfileHeader()
                    
                    History()
                }
            }
            .onAppear {
                Task {
                    let token = try await authVM.getFirebaseToken()
                    await accountVM.getUserPosts(token: token)
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
                URLImageView(imageURL: imageURL)
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
                
                Text(authVM.biography ?? "No bio")
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
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
                    NavigationLink(destination: PostScreen(postId: post.id, location: $locationManager.location)) {
                        PostView(post: $post, location: $locationManager.location) {
                            Task {
                                let token = try await authVM.getFirebaseToken()
                                await accountVM.deletePublication(publicationId: post.id, token: token)
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
    
    //MARK: - Auxiliary Methods
    
    private func shouldDisplay(post: FormattedPost) -> Bool {
        switch accountVM.selectedPostType {
        case .all:
            return true
        case .active:
            return post.type == .active
        case .inactive:
            return post.type == .inactive
        }
    }
}

#Preview {
    AccountScreen()
        .environmentObject(AuthenticationViewModel())
}
