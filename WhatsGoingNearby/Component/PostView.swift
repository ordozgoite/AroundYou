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
        VStack(alignment: .leading) {
            HStack {
                Text(post.username)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                if post.status == .active && post.postSource == .publication {
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
    }
    
    //MARK: - Options
    
    @ViewBuilder
    private func Options() -> some View {
        VStack {
            if post.isFromRecipientUser {
                if post.status == .active {
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
                if let isSubscribed = post.isSubscribed {
                    if isSubscribed {
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
        } else if post.postSource == .lostItem {
            HStack(spacing: 2) {
                Image(systemName: "magnifyingglass")
                    .scaleEffect(0.8)
                
                Text("Lost Something")
                    .font(.caption)
            }
            .foregroundStyle(.gray)
        }
    }
    
    //MARK: - Text
    
    @ViewBuilder
    private func TextView() -> some View {
        VStack(alignment: .leading) {
            if post.postSource == .lostItem {
                Text("Help me to find my... ")
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
                    isFullScreenImageDisplayed = true
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
                            await unlikePublication(publicationId: post.id, token: token) {
                                toggleFeedUpdate($0)
                            }
                        } else {
                            hapticFeedback()
                            post.didLike = true
                            post.likes = (post.likes ?? 0) + 1
                            await likePublication(publicationId: post.id, token: token) {
                                toggleFeedUpdate($0)
                            }
                        }
                    }
                }
                
                Text(String(post.likes ?? 0))
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .onTapGesture {
                        isLikeScreenDisplayed = true
                    }
            }
            
            HStack {
                Image(systemName: "bubble.left")
                    .foregroundColor(.gray)
                
                Text(String(post.comment ?? 0))
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            if post.isLocationVisible ?? false, let distance = post.formattedDistanceToMe {
                HStack {
                    Image(systemName: "map")
                        .foregroundStyle(.gray)
                    
                    Text(distance)
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
    
    // MARK: - Not Real Post Footer
    
    @ViewBuilder
    private func NotRealPostFooter() -> some View {
        HStack {
            Button {
                // TODO: Go to DetailScreen
            } label: {
                HStack {
                    Text("See Details")
                    Image(systemName: "chevron.forward")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 12)
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
            destination: ReportIssueScreen(reportedUserUid: post.userUid, publicationId: post.id, commentId: nil, businessId: nil).environmentObject(authVM),
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
        location: .constant(nil),
        socket: SocketService(),
        deletePost: {},
        toggleFeedUpdate: { _ in }
    )
    .environmentObject(AuthenticationViewModel())
}

//"https:\/\/firebasestorage.googleapis.com:443\/v0\/b\/aroundyou-b8364.appspot.com\/o\/post-image%2F32A37A97-A770-4103-80BF-4614736B2706.jpg?alt=media&token=d4d6ac06-73a9-4805-8a48-7218f8a334dc"

//"https:\/\/firebasestorage.googleapis.com:443\/v0\/b\/aroundyou-b8364.appspot.com\/o\/post-image%2F6014DE96-A1DF-485D-BC5F-A1D1AC35CF71.jpg?alt=media&token=cafbcd10-81bf-48af-9e25-39e06d05143a"
