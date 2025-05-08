//
//  PostView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import SwiftUI
import CoreLocation

struct PostView: View {
    
    @Binding var post: FormattedPost
    @ObservedObject var socket: SocketService
    @ObservedObject var locationManager: LocationManager
    let deletePost: () -> ()
    let toggleFeedUpdate: (Bool) -> ()
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var postVM = PostViewModel()
    
    var body: some View {
        VStack {
            HStack(alignment: .top, spacing: 8) {
                ProfilePic()
                
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 0) {
                        HeaderView()
                        
                        Tag()
                    }
                    
                    TextView()
                    
                    ImagePreview()
                    
                    Footer()
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                handleOnTapGesture()
            }
            .fullScreenCover(isPresented: $postVM.isFullScreenImageDisplayed) {
                FullScreenUrlImage(url: post.imageUrl ?? "")
            }
            
            Navigation()
        }
        
    }
    
    //MARK: - ProfilePic
    
    @ViewBuilder
    private func ProfilePic() -> some View {
        VStack {
            NavigationLink(destination: UserProfileScreen(userUid: post.userUid, socket: socket).environmentObject(authVM)) {
                ProfilePicView(profilePic: post.userProfilePic)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    //MARK: - Header
    
    @ViewBuilder
    private func HeaderView() -> some View {
        VStack(alignment: .leading) {
            HStack {
                Username()
                
                TimeInfo()
                
                
                Spacer()
                
                OptionsButton()
            }
        }
    }
    
    // MARK: - Username
    
    @ViewBuilder
    private func Username() -> some View {
        Text(post.username)
            .fontWeight(.semibold)
            .lineLimit(1)
    }
    
    // MARK: - Time Info
    
    @ViewBuilder
    private func TimeInfo() -> some View {
        if postVM.isActivePublication(post) {
            CircleTimerView(postDate: post.timestamp.timeIntervalSince1970InSeconds, expirationDate: post.expirationDate.timeIntervalSince1970InSeconds)
                .popover(isPresented: $postVM.isTimeLeftPopoverDisplayed) {
                    Text(postVM.getTimeLeftText(forPost: post))
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                        .padding([.leading, .trailing], 10)
                        .presentationCompactAdaptation(.popover)
                }
                .onTapGesture {
                    postVM.isTimeLeftPopoverDisplayed = true
                }
        } else {
            Text(post.timestamp.convertTimestampToDate().formatDatetoPost())
                .foregroundStyle(.gray)
                .font(.caption)
        }
    }
    
    // MARK: - Options Button
    
    @ViewBuilder
    private func OptionsButton() -> some View {
        Image(systemName: "ellipsis")
            .foregroundStyle(.gray)
            .popover(isPresented: $postVM.isOptionsPopoverDisplayed) {
                Options()
            }
            .onTapGesture {
                postVM.isOptionsPopoverDisplayed = true
            }
    }
    
    //MARK: - Options
    
    @ViewBuilder
    private func Options() -> some View {
        VStack {
            if post.isFromRecipientUser {
                if postVM.isActivePublication(post) {
                    EditPostButton()
                    
                    FinishPostButton()
                }
                
                switch post.postSource {
                case .publication:
                    DeletePostButton()
                case .lostItem:
                    DeleteLostItemButton()
                case .report:
                    DeleteReportButton()
                }
            } else if post.postSource == .publication {
                if let isSubscribed = post.isSubscribed {
                    if isSubscribed {
                        DisableNotificationsButton()
                    } else {
                        EnableNotificationsButton()
                    }
                }
                
                Divider()
                
                ReportPostButton()
            }
        }
        .presentationCompactAdaptation(.popover)
    }
    
    // MARK: - Edit Post
    
    @ViewBuilder
    private func EditPostButton() -> some View {
        Button {
            postVM.isOptionsPopoverDisplayed = false
            postVM.isEditPostScreenDisplayed = true
        } label: {
            Text("Edit Post")
            Image(systemName: "pencil")
        }
        .foregroundStyle(.gray)
        .padding()
    }
    
    // MARK: - Finish Post
    
    @ViewBuilder
    private func FinishPostButton() -> some View {
        Button {
            postVM.isOptionsPopoverDisplayed = false
            Task {
                let token = try await authVM.getFirebaseToken()
                try await postVM.finishPublication(postId: post.id, token: token)
                self.post.isFinished = true
            }
        } label: {
            Text("Finish Post")
            Image(systemName: "clock.arrow.circlepath")
        }
        .foregroundStyle(.gray)
        .padding(.horizontal)
    }
    
    // MARK: - Delete Post
    
    @ViewBuilder
    private func DeletePostButton() -> some View {
        Button(role: .destructive) {
            deletePost()
        } label: {
            Text("Delete Post")
            Image(systemName: "trash")
        }
        .padding()
    }
    
    // MARK: - Delete Lost Item
    
    @ViewBuilder
    private func DeleteLostItemButton() -> some View {
        Button(role: .destructive) {
            Task {
                let token = try await authVM.getFirebaseToken()
                await postVM.deleteLostItem(lostItemId: post.id, token: token)
            }
        } label: {
            Text("Delete Lost Item")
            Image(systemName: "trash")
        }
        .padding()
    }
    
    // MARK: - Delete Report
    
    @ViewBuilder
    private func DeleteReportButton() -> some View {
        Button(role: .destructive) {
            Task {
                let token = try await authVM.getFirebaseToken()
                await postVM.deleteReport(reportId: post.id,token: token)
            }
        } label: {
            Text("Delete Report")
            Image(systemName: "trash")
        }
        .padding()
    }
    
    // MARK: - Disable Notifications
    
    @ViewBuilder
    private func DisableNotificationsButton() -> some View {
        Button {
            postVM.isOptionsPopoverDisplayed = false
            Task {
                let token = try await authVM.getFirebaseToken()
                if let isFollowing = await postVM.unfollowPost(postId: self.post.id, token: token) {
                    self.post.isSubscribed = isFollowing
                }
            }
        } label: {
            Text("Disable notifications")
                .foregroundStyle(.gray)
            Image(systemName: "bell.slash.fill")
                .foregroundStyle(.gray)
        }
        .padding()
    }
    
    // MARK: - Enable Notifications
    
    @ViewBuilder
    private func EnableNotificationsButton() -> some View {
        Button {
            postVM.isOptionsPopoverDisplayed = false
            Task {
                let token = try await authVM.getFirebaseToken()
                if let isFollowing = await postVM.followPost(postId: self.post.id, token: token) {
                    self.post.isSubscribed = isFollowing
                }
            }
        } label: {
            Text("Enable notifications")
                .foregroundStyle(.gray)
            Image(systemName: "bell.and.waves.left.and.right")
                .foregroundStyle(.gray)
        }
        .padding()
    }
    
    // MARK: - Report Post
    
    @ViewBuilder
    private func ReportPostButton() -> some View {
        Button {
            postVM.isOptionsPopoverDisplayed = false
            postVM.isReportScreenPresented = true
        } label: {
            Text("Report Post")
                .foregroundStyle(.gray)
            Image(systemName: "exclamationmark.bubble")
                .foregroundStyle(.gray)
        }
        .padding()
    }
    
    //MARK: - Tag
    
    @ViewBuilder
    private func Tag() -> some View {
        if let postTag = post.postTag {
            HStack(spacing: 2) {
                Image(systemName: postTag.iconName)
                    .scaleEffect(0.8)
                
                Text(postTag.title)
                    .font(.caption)
            }
            .foregroundStyle(.gray)
        } else if post.postSource == .lostItem {
            HStack(spacing: 2) {
                Image(systemName: "magnifyingglass")
                    .scaleEffect(0.8)
                
                Text("Lost Something")
                    .font(.caption)
            }
            .foregroundStyle(.red)
        } else if post.postSource == .report {
            HStack(spacing: 2) {
                Image(systemName: "exclamationmark.bubble")
                    .scaleEffect(0.8)
                
                Text("Report")
                    .font(.caption)
            }
            .foregroundStyle(.red)
        }
    }
    
    //MARK: - Text
    
    @ViewBuilder
    private func TextView() -> some View {
        VStack(alignment: .leading) {
            if post.wasFound == false {
                Text("Help me to find my... ")
                    .font(.callout)
                    .foregroundStyle(.gray)
            }
            
            if let text = post.text {
                Text(LocalizedStringKey(text))
                    .textSelection(.enabled)
            }
        }
    }
    
    //MARK: - Image Preview
    
    @ViewBuilder
    private func ImagePreview() -> some View {
        if let url = post.imageUrl {
            PostImageView(imageURL: url)
                .scaledToFit()
                .frame(width: 128)
                .cornerRadius(8)
                .onTapGesture {
                    postVM.isFullScreenImageDisplayed = true
                }
        }
    }
    
    //MARK: - Footer
    
    @ViewBuilder
    private func Footer() -> some View {
        if post.postSource == .publication {
            RealPostFooter()
        } else {
            NotRealPostFooter()
        }
    }
    
    // MARK: - Post Footer
    
    @ViewBuilder
    private func RealPostFooter() -> some View {
        HStack(spacing: 32) {
            Likes()
            
            Comments()
            
            Map()
            
            Spacer()
        }
    }
    
    // MARK: - Likes
    
    @ViewBuilder
    private func Likes() -> some View {
        HStack {
            HeartView(isLiked: Binding(
                get: { post.didLike ?? false },
                set: { post.didLike = $0 }
            )) {
                Task {
                    let token = try await authVM.getFirebaseToken()
                    
                    if post.didLike ?? false {
                        post.didLike = false
                        post.likes = (post.likes ?? 1) - 1
                        await postVM.unlikePublication(publicationId: post.id, token: token) {
                            toggleFeedUpdate($0)
                        }
                    } else {
                        hapticFeedback()
                        post.didLike = true
                        post.likes = (post.likes ?? 0) + 1
                        await postVM.likePublication(publicationId: post.id, token: token) {
                            toggleFeedUpdate($0)
                        }
                    }
                }
            }
            
            Text(String(post.likes ?? 0))
                .font(.subheadline)
                .foregroundColor(.gray)
                .onTapGesture {
                    postVM.isLikeScreenDisplayed = true
                }
        }
    }
    
    // MARK: - Comments
    
    @ViewBuilder
    private func Comments() -> some View {
        HStack {
            Image(systemName: "bubble.left")
                .foregroundColor(.gray)
            
            Text(String(post.comment ?? 0))
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Map
    
    @ViewBuilder
    private func Map() -> some View {
        if post.isLocationVisible ?? false, let distance = post.formattedDistanceToMe {
            HStack {
                Image(systemName: "map")
                    .foregroundStyle(.gray)
                
                Text(distance)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .onTapGesture {
                postVM.isMapScreenPresented = true
            }
        }
    }
    
    // MARK: - Not Real Post Footer
    
    @ViewBuilder
    private func NotRealPostFooter() -> some View {
        HStack {
            if post.wasFound == true {
                ItemFound()
            } else {
                SeeDetails()
            }

            Spacer()
        }
    }
    
    // MARK: - See Details
    
    @ViewBuilder
    private func SeeDetails() -> some View {
        Button {
            if post.postSource == .lostItem {
                postVM.isLostItemDetailScreenPresented = true
            } else if post.postSource == .report {
                postVM.isReportDetailScreenPresented = true
            }
        } label: {
            HStack {
                Text("See Details")
                Image(systemName: "chevron.forward")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 12)
            }
        }
    }
    
    // MARK: - Item Found
    
    @ViewBuilder
    private func ItemFound() -> some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(.green)

            Text("Item Found")
                .font(.subheadline)
                .foregroundColor(.green)
                .bold()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color.green.opacity(0.2)))

    }
    
    //MARK: - Navigation
    
    @ViewBuilder
    private func Navigation() -> some View {
        NavigationLink(
            destination: CommentScreen(postId: post.id, post: $post, locationManager: locationManager, socket: socket).environmentObject(authVM),
            isActive: $postVM.isCommentScreenPresented,
            label: { EmptyView() }
        )
        
        NavigationLink(
            destination: ReportDetailScreen(reportId: post.id).environmentObject(authVM),
            isActive: $postVM.isReportDetailScreenPresented,
            label: { EmptyView() }
        )
        
        NavigationLink(
            destination: LostItemDetailScreen(lostItemId: post.id).environmentObject(authVM),
            isActive: $postVM.isLostItemDetailScreenPresented,
            label: { EmptyView() }
        )
        
        NavigationLink(
            destination: EditPostScreen(post: post, location: $locationManager.location).environmentObject(authVM),
            isActive: $postVM.isEditPostScreenDisplayed,
            label: { EmptyView() }
        )
        
        NavigationLink(
            destination: ReportIssueScreen(reportedUserUid: post.userUid, publicationId: post.id, commentId: nil, businessId: nil).environmentObject(authVM),
            isActive: $postVM.isReportScreenPresented,
            label: { EmptyView() }
        )
        
        if #available(iOS 17.0, *) {
            NavigationLink(
                destination: NewPostLocationScreen(latitude: post.latitude ?? 0, longitude: post.longitude ?? 0, username: post.username, profilePic: post.userProfilePic).environmentObject(authVM),
                isActive: $postVM.isMapScreenPresented,
                label: { EmptyView() }
            )
        } else {
            NavigationLink(
                destination: PostLocationScreen(latitude: post.latitude ?? 0, longitude: post.longitude ?? 0).environmentObject(authVM),
                isActive: $postVM.isMapScreenPresented,
                label: { EmptyView() }
            )
        }
        
        NavigationLink(
            destination: LikeScreen(id: post.id, type: .publication, socket: socket).environmentObject(authVM),
            isActive: $postVM.isLikeScreenDisplayed,
            label: { EmptyView() }
        )
    }
    
    //MARK: - Auxiliary Methods
    
    private func handleOnTapGesture() {
        switch self.post.postSource {
        case .publication:
            postVM.isCommentScreenPresented = true
        case .lostItem:
            postVM.isLostItemDetailScreenPresented = true
        case .report:
            postVM.isReportDetailScreenPresented = true
        }
    }
}

#Preview {
    PostView(
        post: .constant(FormattedPost(
            id: "680006cd9c7c5a27d55e6a34",
            userUid: "ntDPci9E8ZURHYcqFfektUSFWw53",
            userProfilePic: "https://www.apple.com/leadership/images/bio/tim-cook_image.png.og.png?1736784653666",
            username: "ordozgoite",
            timestamp: 1744832205133,
            expirationDate: 1744918605133,
            text: "AirPods Pro 2ª geração",
            likes: nil,
            didLike: nil,
            comment: nil,
            latitude: -60.022406872388324,
            longitude: -3.1263690427109263,
            distanceToMe: nil,
            isFromRecipientUser: false,
            isLocationVisible: false,
            tag: nil,
            imageUrl: "https://m.media-amazon.com/images/I/51OoKCakCfL._AC_UF350,350_QL80_.jpg",
            isOwnerFarAway: nil,
            isFinished: nil,
            duration: nil,
            isSubscribed: nil,
            source: "lostItem"
        )),
        socket: SocketService(),
        locationManager: LocationManager(),
        deletePost: {},
        toggleFeedUpdate: { _ in }
    )
    .environmentObject(AuthenticationViewModel())
}

//"https:\/\/firebasestorage.googleapis.com:443\/v0\/b\/aroundyou-b8364.appspot.com\/o\/post-image%2F32A37A97-A770-4103-80BF-4614736B2706.jpg?alt=media&token=d4d6ac06-73a9-4805-8a48-7218f8a334dc"

//"https:\/\/firebasestorage.googleapis.com:443\/v0\/b\/aroundyou-b8364.appspot.com\/o\/post-image%2F6014DE96-A1DF-485D-BC5F-A1D1AC35CF71.jpg?alt=media&token=cafbcd10-81bf-48af-9e25-39e06d05143a"
