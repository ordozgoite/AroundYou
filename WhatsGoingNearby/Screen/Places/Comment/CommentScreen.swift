//
//  CommentScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 14/02/24.
//

import SwiftUI
import CoreLocation

struct CommentScreen: View, PostViewActionHandler {
    @State var post: FormattedPost
    private let maxCommentLength = 250
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @EnvironmentObject var navCoordinator: NavigationCoordinator
    @EnvironmentObject var socket: SocketService
    @EnvironmentObject var locationManager: LocationManager
    @StateObject private var commentVM = CommentViewModel()
    @Environment(\.presentationMode) var presentationMode
    @FocusState private var commentIsFocused: Bool
    
    var body: some View {
        ZStack {
            VStack {
                ScrollView {
                    PostView(post: post, delegate: self, isClickable: false)
                        .padding()
                    
                    Divider()
                    
                    if post.postSource == .publication {
                        Comments()
                    }
                }
                
                if post.postSource == .publication {
                    CommentTextField()
                }
            }
            
            AYErrorAlert(message: commentVM.overlayError.1 , isErrorAlertPresented: $commentVM.overlayError.0)
        }
        .onAppear {
            startUpdatingComments()
        }
        .onDisappear {
            stopTimer()
        }
        .navigationTitle("Comments")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: AppRoute.self) { destination in
            switch destination {
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
            case .map(let post):
                if #available(iOS 17.0, *) {
                    NewPostLocationScreen(latitude: post.latitude ?? 0, longitude: post.longitude ?? 0, username: post.username, profilePic: post.userProfilePic)
                } else {
                    PostLocationScreen(latitude: post.latitude ?? 0, longitude: post.longitude ?? 0)
                }
            default:
                EmptyView()
            }
        }
    }
    
    //MARK: - Comments
    
    @ViewBuilder
    private func Comments() -> some View {
        VStack {
            Disclaimer()
            Divider()
            
            ForEach($commentVM.comments) { $comment in
                CommentView(isPostFromRecipientUser: post.isFromRecipientUser, postType: post.status, socket: socket, comment: $comment, deleteComment: {
                    Task {
                        let token = try await authVM.getFirebaseToken()
                        await commentVM.deleteComment(commentId: comment.id, token: token)
                    }
                }, reply: {
                    commentIsFocused = true
                    commentVM.repliedComment = comment
                }, location: $locationManager.location)
                .padding()
                Divider()
            }
        }
    }
    
    // MARK: - Disclaimer
    
    @ViewBuilder
    private func Disclaimer() -> some View {
        AYDisclaimerView(text: "Only people nearby this post can interact with it, including the owner.")
            .padding()
    }
    
    //MARK: - Comment Text Field
    
    @ViewBuilder
    private func CommentTextField() -> some View {
        VStack {
            if let comment = commentVM.repliedComment {
                HStack {
                    HStack {
                        Text("Replying to \(comment.username)")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                        
                        Image(systemName: "xmark")
                            .scaleEffect(0.8)
                            .foregroundStyle(.blue)
                    }
                    .onTapGesture {
                        commentVM.repliedComment = nil
                    }
                    
                    Spacer()
                }
                .padding(10)
            }
            
            HStack {
                TextField(commentVM.repliedComment == nil ? "Add a comment... " : "Add a reply...", text: $commentVM.newCommentText, axis: .vertical)
                    .padding(10)
                    .background(LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                    .cornerRadius(20)
                    .shadow(color: .gray, radius: 10)
                    .focused($commentIsFocused)
                    .onChange(of: commentVM.newCommentText) { newValue in
                        if newValue.count > maxCommentLength {
                            commentVM.newCommentText = String(newValue.prefix(maxCommentLength))
                        }
                    }
                
                if !commentVM.newCommentText.isEmpty {
                    Button(action: {
                        commentIsFocused = false
                        Task {
                            try await postNewComment()
                        }
                    }) {
                        Image(systemName: "paperplane.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding()
        }
    }
    
    
    //MARK: - Auxiliary methods
    
    private func postNewComment() async throws {
        if let location = locationManager.location {
            let token = try await authVM.getFirebaseToken()
            
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            
            await commentVM.postNewComment(publicationId: post.id, text: commentVM.newCommentText, latitude: latitude, longitude: longitude, token: token)
        }
    }
    
    private func startUpdatingComments() {
        commentVM.timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            Task {
                let token = try await authVM.getFirebaseToken()
                await commentVM.getAllComments(publicationId: post.id, token: token)
            }
        }
        commentVM.timer?.fire()
    }
    
    private func stopTimer() {
        commentVM.timer?.invalidate()
    }
}

// MARK: - Post View Protocol

extension CommentScreen {
    func postViewDidLikePublication(_ content: FormattedPost) {
        if post.likes != nil {
            post.likes! += 1
            post.didLike = true
        }
    }
    
    func postViewDidUnlikePublication(_ content: FormattedPost) {
        if post.likes != nil {
            post.likes! -= 1
            post.didLike = false
        }
    }
    
    func postViewDidDeletePublication(_ content: FormattedPost) {
        navCoordinator.goBack()
    }
    
    func postViewDidDeleteLostItem(_ content: FormattedPost) {
        // Nunca vai acontecer aqui
    }
    
    func postViewDidDeleteReport(_ content: FormattedPost) {
        // Nunca vai acontecer aqui
    }
    
    func postViewDidFollow(_ content: FormattedPost) {
        post.isSubscribed = true
    }
    
    func postViewDidUnfollow(_ content: FormattedPost) {
        post.isSubscribed = false
    }
    
    func postViewDidMarkAsCompleted(_ content: FormattedPost) {
        post.isFinished = true
    }
}

//#Preview {
//    CommentScreen(postId: "", post: .constant(FormattedPost(
//        id: "", userUid: "", userProfilePic: "https://www.bloomberglinea.com/resizer/PLUNbQCzVan6SFJ1RQ3CcBj6js8=/600x0/filters:format(webp):quality(75)/cloudfront-us-east-1.images.arcpublishing.com/bloomberglinea/S5ZMXTXZINE2JBQAV7MECJA7KM.jpg",
//        username: "TimCook",
//        timestamp: Int(Date().timeIntervalSince1970), expirationDate: Int(Date().timeIntervalSince1970),
//        text: "Alguém sabe quando lança o Apple Vision Pro?", likes: 2, didLike: true, comment: 2, latitude: -3.125847431319091, longitude: -60.022035207661695, distanceToMe: 50.0,  isFromRecipientUser: true, isLocationVisible: false, isSubscribed: false)), location: <#Binding<CLLocation?>#>)
//    .environmentObject(AuthenticationViewModel())
//}
