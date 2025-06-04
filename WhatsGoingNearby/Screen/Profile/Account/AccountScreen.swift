//
//  ProfileScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import SwiftUI

struct AccountScreen: View, PostViewActionHandler {
    @EnvironmentObject var authVM: AuthenticationViewModel
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var socket: SocketService
    @EnvironmentObject var navCoordinator: NavigationCoordinator
    @StateObject private var accountVM = AccountViewModel()
    
    @State private var refreshObserver = NotificationCenter.default
        .publisher(for: .updateUserProfilePosts)
    
    var body: some View {
        NavigationStack(path: $navCoordinator.path) {
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
            .navigationDestination(for: AppRoute.self) { destination in
                switch destination {
                case .comment(let post):
                    CommentScreen(post: post)
                case .reportDetail(let post):
                    ReportDetailScreen(reportId: post.id)
                case .lostItemDetail(let post):
                    LostItemDetailScreen(lostItemId: post.id)
                case .editPost(let post):
                    EditPostScreen(post: post)
                case .reportIssue(let post):
                    ReportIssueScreen(reportedUserUid: post.userUid, publicationId: post.id, commentId: nil, businessId: nil)
                case .like(let post):
                    LikeScreen(id: post.id, type: .publication)
                case .postMap(let post):
                    if #available(iOS 17.0, *) {
                        NewPostLocationScreen(latitude: post.latitude ?? 0, longitude: post.longitude ?? 0, username: post.username, profilePic: post.userProfilePic)
                    } else {
                        PostLocationScreen(latitude: post.latitude ?? 0, longitude: post.longitude ?? 0)
                    }
                case .editProfile:
                    EditProfileScreen()
                case .settings:
                    SettingsScreen()
                case .userProfile(let userUid):
                    UserProfileScreen(userUid: userUid)
                default:
                    EmptyView()
                }
            }
            .toolbar {
                ToolbarItem {
                    Button {
                        navCoordinator.navigate(to: .settings)
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
        }
    }
    
    //MARK: - Profile Header
    
    @ViewBuilder
    private func ProfileHeader() -> some View {
        VStack(spacing: 16) {
            if let imageURL = authVM.profilePic {
                URLNotTapableImageView(imageURL: imageURL)
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
            navCoordinator.navigate(to: .editProfile)
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
                    PostView(post: post, delegate: self, isClickable: true)
                        .padding()
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

extension AccountScreen {
    func postViewDidLikePublication(_ content: FormattedPost) {
        accountVM.likePost(withId: content.id)
    }
    
    func postViewDidUnlikePublication(_ content: FormattedPost) {
        accountVM.unlikePost(withId: content.id)
    }
    
    func postViewDidDeletePublication(_ content: FormattedPost) {
        accountVM.removePost(withId: content.id)
    }
    
    func postViewDidDeleteLostItem(_ content: FormattedPost) {
        accountVM.removePost(withId: content.id)
    }
    
    func postViewDidDeleteReport(_ content: FormattedPost) {
        accountVM.removePost(withId: content.id)
    }
    
    func postViewDidFollow(_ content: FormattedPost) {
        accountVM.followPost(withId: content.id)
    }
    
    func postViewDidUnfollow(_ content: FormattedPost) {
        accountVM.unfollowPost(withId: content.id)
    }
    
    func postViewDidMarkAsCompleted(_ content: FormattedPost) {
        accountVM.finishPost(withId: content.id)
    }
}

#Preview {
    AccountScreen()
        .environmentObject(AuthenticationViewModel())
}
