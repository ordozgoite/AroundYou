//
//  PostView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import SwiftUI

struct PostView: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @Binding var post: FormattedPost
    
    @State private var isTimeLeftPopoverDisplayed: Bool = false
    @State private var isOptionsPopoverDisplayed: Bool = false
    @State private var isReportScreenPresented: Bool = false
    @State private var isMapScreenPresented: Bool = false
    @State private var isLikeScreenDisplayed: Bool = false
    
    @State private var isFollowingPost: Bool = false
    @State private var isUnfollowingPost: Bool = false
    
    let deletePost: () -> ()
    
    var body: some View {
        VStack {
            HStack(alignment: .top, spacing: 8) {
                ProfilePic()
                
                VStack(alignment: .leading, spacing: 16) {
                    HeaderView()
                    
                    TextView()
                    
                    InteractionsView()
                }
            }
            NavigationLink(
                destination: ReportScreen(reportedUserUid: post.userUid, publicationId: post.id, commentId: nil).environmentObject(authVM),
                isActive: $isReportScreenPresented,
                label: { EmptyView() }
            )
            
            if #available(iOS 17.0, *) {
                NavigationLink(
                    destination: NewMapScreen(latitude: post.latitude ?? 0, longitude: post.longitude ?? 0, userName: post.userName, profilePic: post.userProfilePic).environmentObject(authVM),
                    isActive: $isMapScreenPresented,
                    label: { EmptyView() }
                )
            } else {
                NavigationLink(
                    destination: MapScreen(latitude: post.latitude ?? 0, longitude: post.longitude ?? 0).environmentObject(authVM),
                    isActive: $isMapScreenPresented,
                    label: { EmptyView() }
                )
            }
            
            NavigationLink(
                destination: LikeScreen(id: post.id, type: .publication).environmentObject(authVM),
                isActive: $isLikeScreenDisplayed,
                label: { EmptyView() }
            )
        }
        
    }
    
    //MARK: - ProfilePic
    
    @ViewBuilder
    private func ProfilePic() -> some View {
        VStack {
            NavigationLink(destination: UserProfileScreen(userUid: post.userUid).environmentObject(authVM)) {
                ProfilePicView(profilePic: post.userProfilePic)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    //MARK: - Header
    
    @ViewBuilder
    private func HeaderView() -> some View {
        HStack {
            Text(post.userName)
                .fontWeight(.semibold)
            
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
                Text("Expired")
                    .foregroundStyle(.gray)
                    .font(.subheadline)
            }
            
            
            Spacer()
            
            Image(systemName: "ellipsis")
                .foregroundStyle(.gray)
                .popover(isPresented: $isOptionsPopoverDisplayed) {
                    VStack {
                        if post.isFromRecipientUser {
                            Button(role: .destructive, action: {
                                deletePost()
                            }) {
                                Text("Delete Post")
                                Image(systemName: "trash")
                            }
                            .padding()
                        }
                        
                        if !post.isFromRecipientUser {
                            if post.isSubscribed {
                                Button(action: {
                                    Task {
                                        let token = try await authVM.getFirebaseToken()
                                        await unfollowPost(token: token)
                                    }
                                }) {
                                    if isUnfollowingPost {
                                        Text("Unfollowing post")
                                            .foregroundStyle(.gray)
                                        ProgressView()
                                    } else {
                                        Text("Unfollow post")
                                            .foregroundStyle(.gray)
                                        Image(systemName: "bell.slash.fill")
                                            .foregroundStyle(.gray)
                                    }
                                }
                                .padding()
                            } else {
                                Button(action: {
                                    Task {
                                        let token = try await authVM.getFirebaseToken()
                                        await followPost(token: token)
                                    }
                                }) {
                                    if isFollowingPost {
                                        Text("Following post")
                                            .foregroundStyle(.gray)
                                        ProgressView()
                                    } else {
                                        Text("Follow post")
                                            .foregroundStyle(.gray)
                                        Image(systemName: "bell.and.waves.left.and.right")
                                            .foregroundStyle(.gray)
                                    }
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
                .onTapGesture {
                    isOptionsPopoverDisplayed = true
                }
        }
    }
    
    //MARK: - Text
    
    @ViewBuilder
    private func TextView() -> some View {
        Text(post.text)
    }
    
    //MARK: - Interactions
    
    @ViewBuilder
    private func InteractionsView() -> some View {
        HStack(spacing: 32) {
            HStack {
                Image(systemName: post.didLike ? "heart.fill" : "heart")
                    .foregroundColor(post.didLike ? .red : .gray)
                    .onTapGesture {
                        Task {
                            let token = try await authVM.getFirebaseToken()
                            if post.didLike {
                                post.didLike = false
                                post.likes -= 1
                                await unlikePublication(publicationId: post.id, token: token)
                            } else {
                                hapticFeedback()
                                post.didLike = true
                                post.likes += 1
                                await likePublication(publicationId: post.id, token: token)
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
                    
                    Text("\(post.formattedDistanceToMe!)m")
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
    
    //MARK: - Auxiliary Methods
    
    private func likePublication(publicationId: String, token: String) async {
        let response = await AYServices.shared.likePublication(publicationId: publicationId, token: token)
        
        switch response {
        case .success:
            print("❤️ Publication liked!")
        case .failure(let error):
            print("❌ Error: \(error)")
        }
    }
    
    private func unlikePublication(publicationId: String, token: String) async {
        let response = await AYServices.shared.unlikePublication(publicationId: publicationId, token: token)
        
        switch response {
        case .success:
            print("💔 Publication unliked!")
        case .failure(let error):
            print("❌ Error: \(error)")
        }
    }
    
    private func followPost(token: String) async {
        isFollowingPost = true
        let result = await AYServices.shared.subscribeUserToPublication(publicationId: self.post.id, token: token)
        isFollowingPost = false
        
        switch result {
        case .success:
            post.isSubscribed = true
        case .failure(let error):
            print("❌ Error: \(error)")
        }
    }
    
    private func unfollowPost(token: String) async {
        isUnfollowingPost = true
        let result = await AYServices.shared.unsubscribeUser(publicationId: self.post.id, token: token)
        isUnfollowingPost = false
        
        switch result {
        case .success:
            post.isSubscribed = false
        case .failure(let error):
            print("❌ Error: \(error)")
        }
    }
    
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
}

#Preview {
    PostView(post: .constant(FormattedPost(
        id: "", userUid: "", userProfilePic: "https://www.bloomberglinea.com/resizer/PLUNbQCzVan6SFJ1RQ3CcBj6js8=/600x0/filters:format(webp):quality(75)/cloudfront-us-east-1.images.arcpublishing.com/bloomberglinea/S5ZMXTXZINE2JBQAV7MECJA7KM.jpg",
        userName: "Victor Ordozgoite",
        timestamp: Int(Date().timeIntervalSince1970), expirationDate: Int(Date().timeIntervalSince1970),
        text: "Alguém sabe quando o KFC vai ser inaugurado?? Já faz tempo que eles estão anunciando...", likes: 2, didLike: true, comment: 2, latitude: -3.125847431319091, longitude: -60.022035207661695, distanceToMe: 50.0, isFromRecipientUser: true, isLocationVisible: false, isSubscribed: false)), deletePost: {})
    .environmentObject(AuthenticationViewModel())
}
