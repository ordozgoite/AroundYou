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
    @Binding var location: CLLocation?
    @ObservedObject var socket: SocketService
    let deletePost: () -> ()
    let toggleFeedUpdate: (Bool) -> ()
    
    @State private var isTimeLeftPopoverDisplayed: Bool = false
    @State private var isOptionsPopoverDisplayed: Bool = false
    @State private var isReportScreenPresented: Bool = false
    @State private var isMapScreenPresented: Bool = false
    @State private var isLikeScreenDisplayed: Bool = false
    @State private var isFullScreenImageDisplayed: Bool = false
    @State private var isEditPostScreenDisplayed: Bool = false
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    
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
            .fullScreenCover(isPresented: $isFullScreenImageDisplayed) {
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
        HStack {
            Text(post.username)
                .fontWeight(.semibold)
                .lineLimit(1)
            
            if post.type == .active {
                CircleTimerView(postDate: post.timestamp.timeIntervalSince1970InSeconds, expirationDate: post.expirationDate.timeIntervalSince1970InSeconds)
                    .popover(isPresented: $isTimeLeftPopoverDisplayed) {
                        Text(getTimeLeftText())
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                            .padding([.leading, .trailing], 10)
                            .presentationCompactAdaptation(.popover)
                    }
                    .onTapGesture {
                        isTimeLeftPopoverDisplayed = true
                    }
            } else {
                Text(post.timestamp.convertTimestampToDate().formatDatetoPost())
                    .foregroundStyle(.gray)
                    .font(.caption)
            }
            
            
            Spacer()
            
            Image(systemName: "ellipsis")
                .foregroundStyle(.gray)
                .popover(isPresented: self.$isOptionsPopoverDisplayed) {
                    Options()
                }
                .onTapGesture {
                    self.isOptionsPopoverDisplayed = true
                }
        }
    }
    
    //MARK: - Options
    
    @ViewBuilder
    private func Options() -> some View {
        VStack {
            if post.isFromRecipientUser {
                if post.type == .active {
                    Button {
                        isOptionsPopoverDisplayed = false
                        isEditPostScreenDisplayed = true
                    } label: {
                        Text("Edit Post")
                        Image(systemName: "pencil")
                    }
                    .foregroundStyle(.gray)
                    .padding()
                    
                    Button {
                        isOptionsPopoverDisplayed = false
                        Task {
                            let token = try await authVM.getFirebaseToken()
                            await finishPublication(token: token)
                        }
                    } label: {
                        Text("Finish Post")
                        Image(systemName: "clock.arrow.circlepath")
                    }
                    .foregroundStyle(.gray)
                    .padding(.horizontal)
                }
                
                Button(role: .destructive, action: {
                    deletePost()
                }) {
                    Text("Delete Post")
                    Image(systemName: "trash")
                }
                .padding()
            } else {
                if post.isSubscribed {
                    Button(action: {
                        isOptionsPopoverDisplayed = false
                        Task {
                            let token = try await authVM.getFirebaseToken()
                            if let isFollowing = await unfollowPost(postId: self.post.id, token: token) {
                                self.post.isSubscribed = isFollowing
                            }
                        }
                    }) {
                        Text("Disable notifications")
                            .foregroundStyle(.gray)
                        Image(systemName: "bell.slash.fill")
                            .foregroundStyle(.gray)
                    }
                    .padding()
                } else {
                    Button {
                        isOptionsPopoverDisplayed = false
                        Task {
                            let token = try await authVM.getFirebaseToken()
                            if let isFollowing = await followPost(postId: self.post.id, token: token) {
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
                
                Divider()
                
                Button(action: {
                    isOptionsPopoverDisplayed = false
                    isReportScreenPresented = true
                }) {
                    Text("Report Post")
                        .foregroundStyle(.gray)
                    Image(systemName: "exclamationmark.bubble")
                        .foregroundStyle(.gray)
                }
                .padding()
            }
        }
        .presentationCompactAdaptation(.popover)
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
            .foregroundStyle(postTag.color)
        }
    }
    
    //MARK: - Text
    
    @ViewBuilder
    private func TextView() -> some View {
        if let text = post.text {
            Text(LocalizedStringKey(text))
                .textSelection(.enabled)
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
                    isFullScreenImageDisplayed = true
                }
        }
    }
    
    //MARK: - Footer
    
    @ViewBuilder
    private func Footer() -> some View {
        HStack(spacing: 32) {
            HStack {
                HeartView(isLiked: $post.didLike) {
                    Task {
                        let token = try await authVM.getFirebaseToken()
                        if post.didLike {
                            post.didLike = false
                            post.likes -= 1
                            await unlikePublication(publicationId: post.id, token: token) { toggleFeedUpdate($0) }
                        } else {
                            hapticFeedback()
                            post.didLike = true
                            post.likes += 1
                            await likePublication(publicationId: post.id, token: token) { toggleFeedUpdate($0) }
                        }
                    }
                }
                
                Text(String(post.likes))
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .onTapGesture {
                        isLikeScreenDisplayed = true
                    }
            }
            HStack {
                Image(systemName: "bubble.left")
                    .foregroundColor(.gray)
                
                Text(String(post.comment))
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            if post.isLocationVisible {
                HStack {
                    Image(systemName: "map")
                        .foregroundStyle(.gray)
                    
                    Text(post.formattedDistanceToMe!)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .onTapGesture {
                    isMapScreenPresented = true
                }
            }
            
            Spacer()
        }
    }
    
    //MARK: - Navigation
    
    @ViewBuilder
    private func Navigation() -> some View {
        NavigationLink(
            destination: EditPostScreen(post: post, location: $location).environmentObject(authVM),
            isActive: $isEditPostScreenDisplayed,
            label: { EmptyView() }
        )
        
        NavigationLink(
            destination: ReportScreen(reportedUserUid: post.userUid, publicationId: post.id, commentId: nil).environmentObject(authVM),
            isActive: $isReportScreenPresented,
            label: { EmptyView() }
        )
        
        if #available(iOS 17.0, *) {
            NavigationLink(
                destination: NewPostLocationScreen(latitude: post.latitude ?? 0, longitude: post.longitude ?? 0, username: post.username, profilePic: post.userProfilePic).environmentObject(authVM),
                isActive: $isMapScreenPresented,
                label: { EmptyView() }
            )
        } else {
            NavigationLink(
                destination: PostLocationScreen(latitude: post.latitude ?? 0, longitude: post.longitude ?? 0).environmentObject(authVM),
                isActive: $isMapScreenPresented,
                label: { EmptyView() }
            )
        }
        
        NavigationLink(
            destination: LikeScreen(id: post.id, type: .publication, socket: socket).environmentObject(authVM),
            isActive: $isLikeScreenDisplayed,
            label: { EmptyView() }
        )
    }
    
    //MARK: - Auxiliary Methods
    
    private func getTimeLeftText() -> LocalizedStringKey {
        var timeLeft: Int
        var pluralModifier: String = ""
        
        let timeLeftInSeconds = post.expirationDate.timeIntervalSince1970InSeconds - getCurrentDateTimestamp()
        if timeLeftInSeconds < 60 {
            timeLeft = timeLeftInSeconds
            if timeLeft != 1 { pluralModifier = "s" }
            return LocalizedStringKey("\(timeLeft) second\(pluralModifier) to expire")
        } else if timeLeftInSeconds < 3600 {
            timeLeft = Int(timeLeftInSeconds / 60)
            if timeLeft != 1 { pluralModifier = "s" }
            return LocalizedStringKey("\(timeLeft) minute\(pluralModifier) to expire")
        } else {
            timeLeft = Int(timeLeftInSeconds / 3600)
            if timeLeft != 1 { pluralModifier = "s" }
            return LocalizedStringKey("\(timeLeft) hour\(pluralModifier) to expire")
        }
    }
    
    private func followPost(postId: String, token: String) async -> Bool? {
        let result = await AYServices.shared.subscribeUserToPublication(publicationId: postId, token: token)
        
        switch result {
        case .success:
            return true
        case .failure:
            return nil
        }
    }
    
    private func unfollowPost(postId: String, token: String) async -> Bool? {
        let result = await AYServices.shared.unsubscribeUser(publicationId: postId, token: token)
        
        switch result {
        case .success:
            return false
        case .failure:
            return nil
        }
    }
    
    private func likePublication(publicationId: String, token: String, toggleFeedUpdate: (Bool) -> ()) async {
        toggleFeedUpdate(false)
        _ = await AYServices.shared.likePublication(publicationId: publicationId, token: token)
        toggleFeedUpdate(true)
    }
    
    private func unlikePublication(publicationId: String, token: String, toggleFeedUpdate: (Bool) -> ()) async {
        toggleFeedUpdate(false)
        _ = await AYServices.shared.unlikePublication(publicationId: publicationId, token: token)
        toggleFeedUpdate(true)
    }
    
    private func finishPublication(token: String) async {
        let result = await AYServices.shared.finishPublication(publicationId: post.id, token: token)
        
        switch result {
        case .success:
            post.isFinished = true
        case .failure:
            print("❌ Error trying to Finish Publication.")
        }
    }
    
    private func refreshFeed() {
        NotificationCenter.default.post(name: .refreshLocationSensitiveData, object: nil)
    }
}

//#Preview {
//    PostView(post: .constant(FormattedPost(
//        id: "", userUid: "", userProfilePic: "https://www.bloomberglinea.com/resizer/PLUNbQCzVan6SFJ1RQ3CcBj6js8=/600x0/filters:format(webp):quality(75)/cloudfront-us-east-1.images.arcpublishing.com/bloomberglinea/S5ZMXTXZINE2JBQAV7MECJA7KM.jpg",
//        username: "ordozgoite",
//        timestamp: Int(Date().timeIntervalSince1970), expirationDate: Int(Date().timeIntervalSince1970),
//        text: "Alguém sabe quando o KFC vai ser inaugurado?? Já faz tempo que eles estão anunciando...", likes: 2, didLike: true, comment: 2, latitude: -3.125847431319091, longitude: -60.022035207661695, distanceToMe: 50.0, isFromRecipientUser: true, isLocationVisible: false, isSubscribed: false)), deletePost: {})
//    .environmentObject(AuthenticationViewModel())
//}
