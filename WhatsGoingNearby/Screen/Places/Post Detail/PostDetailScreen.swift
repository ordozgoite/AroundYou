//
//  PostDetailScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 03/08/26.
//

import SwiftUI
import CoreLocation

struct PostDetailScreen: View, PostViewActionHandler {
    let postId: String
    
    private let maxCommentLength = 250
    
    @EnvironmentObject private var authVM: AuthenticationViewModel
    @EnvironmentObject private var navCoordinator: NavigationCoordinator
    @EnvironmentObject private var socket: SocketService
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var placesVM: PlacesViewModel
    
    @StateObject private var postDetailVM = PostDetailViewModel()
    
    @FocusState private var commentIsFocused: Bool
    
    var body: some View {
        ZStack {
            content
            
            AYErrorAlert(
                message: postDetailVM.overlayError.1,
                isErrorAlertPresented: $postDetailVM.overlayError.0
            )
        }
        .task {
            await loadInitialContent()
        }
        .navigationTitle("Comments")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Main Content
    
    @ViewBuilder
    private var content: some View {
        if let post = postDetailVM.post {
            PostContent(post: post)
        } else if postDetailVM.isLoadingPost {
            PostLoadingView()
        } else {
            // Em caso de erro, o AYErrorAlert será apresentado.
            // Não é necessário exibir outro estado de erro na tela.
            Color.clear
        }
    }
    
    // MARK: - Post Content
    
    @ViewBuilder
    private func PostContent(post: FormattedPost) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                PostView(
                    post: post,
                    delegate: self,
                    isClickable: false
                )
                .padding()
                
                if post.postSource == .publication {
                    Divider()
                    
                    if postDetailVM.isLoadingComments {
                        CommentsLoadingView()
                    } else if postDetailVM.hasLoadedComments {
                        Comments(post: post)
                    }
                }
            }
            
            if post.postSource == .publication,
               postDetailVM.hasLoadedComments {
                CommentTextField(post: post)
            }
        }
    }
    
    // MARK: - Loading Views
    
    @ViewBuilder
    private func PostLoadingView() -> some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading post...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }
    
    @ViewBuilder
    private func CommentsLoadingView() -> some View {
        VStack(spacing: 12) {
            ProgressView()
            
            Text("Loading comments...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Comments
    
    @ViewBuilder
    private func Comments(post: FormattedPost) -> some View {
        VStack(spacing: 0) {
            Disclaimer()
            
            Divider()
            
            if postDetailVM.comments.isEmpty {
                EmptyCommentsView()
            } else {
                ForEach($postDetailVM.comments) { $comment in
                    CommentView(
                        isPostFromRecipientUser: post.isFromRecipientUser,
                        postType: post.status,
                        comment: $comment,
                        deleteComment: {
                            Task {
                                await deleteComment(
                                    commentId: comment.id
                                )
                            }
                        },
                        reply: {
                            postDetailVM.repliedComment = comment
                            commentIsFocused = true
                        },
                        location: $locationManager.location
                    )
                    .padding()
                    
                    Divider()
                }
            }
        }
    }
    
    @ViewBuilder
    private func EmptyCommentsView() -> some View {
        VStack(spacing: 10) {
            Image(systemName: "bubble.left")
                .font(.system(size: 30))
                .foregroundColor(.secondary)
            
            Text("No comments yet")
                .font(.headline)
            
            Text("Be the first person to comment.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal)
    }
    
    // MARK: - Disclaimer
    
    @ViewBuilder
    private func Disclaimer() -> some View {
        AYDisclaimerView(
            text: "Only people nearby this post can interact with it, including the owner."
        )
        .padding()
    }
    
    // MARK: - Comment Text Field
    
    @ViewBuilder
    private func CommentTextField(post: FormattedPost) -> some View {
        VStack(spacing: 0) {
            if let repliedComment = postDetailVM.repliedComment {
                HStack {
                    Button {
                        postDetailVM.repliedComment = nil
                    } label: {
                        HStack {
                            Text(
                                "Replying to \(repliedComment.username)"
                            )
                            .font(.subheadline)
                            
                            Image(systemName: "xmark")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 10)
            }
            
            HStack {
                TextField(
                    postDetailVM.repliedComment == nil
                        ? "Add a comment..."
                        : "Add a reply...",
                    text: $postDetailVM.newCommentText,
                    axis: .vertical
                )
                .padding(10)
                .background(
                    Color.gray.opacity(0.1)
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: 20)
                )
                .focused($commentIsFocused)
                .onChange(
                    of: postDetailVM.newCommentText
                ) { newValue in
                    limitCommentLength(newValue)
                }
                
                if postDetailVM.isPostingComment {
                    ProgressView()
                        .frame(width: 24, height: 24)
                } else if !postDetailVM.newCommentText.isEmpty {
                    Button {
                        commentIsFocused = false
                        
                        Task {
                            await postNewComment(
                                postId: post.id
                            )
                        }
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding()
        }
        .background(Color(uiColor: .systemBackground))
    }
    
    // MARK: - Initial Loading
    
    private func loadInitialContent() async {
        do {
            let token = try await authVM.getFirebaseToken()
            let location = try getCurrentLocation()
            
            async let postRequest: Void = postDetailVM.getPost(
                postId: postId,
                latitude: location.latitude,
                longitude: location.longitude,
                token: token
            )
            
            async let commentsRequest: Void = postDetailVM.getAllComments(
                publicationId: postId,
                token: token,
                showLoading: true
            )
            
            await postRequest
            await commentsRequest
            
        } catch {
            postDetailVM.overlayError = (
                true,
                LocalizedStringKey(error.localizedDescription)
            )
        }
    }
    
    // MARK: - Comment Actions
    
    private func postNewComment(postId: String) async {
        guard let location = locationManager.location else {
            return
        }
        
        do {
            let token = try await authVM.getFirebaseToken()
            
            await postDetailVM.postNewComment(
                publicationId: postId,
                text: postDetailVM.newCommentText,
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                token: token
            )
        } catch {
            postDetailVM.overlayError = (
                true,
                LocalizedStringKey(error.localizedDescription)
            )
        }
    }
    
    private func deleteComment(commentId: String) async {
        do {
            let token = try await authVM.getFirebaseToken()
            
            await postDetailVM.deleteComment(
                commentId: commentId,
                token: token
            )
        } catch {
            postDetailVM.overlayError = (
                true,
                LocalizedStringKey(error.localizedDescription)
            )
        }
    }
    
    private func limitCommentLength(_ text: String) {
        guard text.count > maxCommentLength else {
            return
        }
        
        postDetailVM.newCommentText = String(
            text.prefix(maxCommentLength)
        )
    }
    
    // MARK: - Location
    
    private func getCurrentLocation() throws -> Location {
        locationManager.requestLocation()
        
        guard let location = locationManager.location else {
            throw LocationError.unableToGetCurrentLocation
        }
        
        return Location(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
    }
}

// MARK: - Post View Protocol

extension PostDetailScreen {
    
    func postViewDidLikePublication(
        _ content: FormattedPost
    ) {
        updatePost { post in
            guard let likes = post.likes else {
                return
            }
            
            post.likes = likes + 1
            post.didLike = true
        }
    }
    
    func postViewDidUnlikePublication(
        _ content: FormattedPost
    ) {
        updatePost { post in
            guard let likes = post.likes else {
                return
            }
            
            post.likes = max(0, likes - 1)
            post.didLike = false
        }
    }
    
    func postViewDidDeletePublication(
        _ content: FormattedPost
    ) {
        placesVM.invalidatePublicationCreationEligibility()
        navCoordinator.goBack()
    }
    
    func postViewDidDeleteLostItem(
        _ content: FormattedPost
    ) {
        // Nunca vai acontecer aqui.
    }
    
    func postViewDidDeleteReport(
        _ content: FormattedPost
    ) {
        // Nunca vai acontecer aqui.
    }
    
    func postViewDidFollow(
        _ content: FormattedPost
    ) {
        updatePost { post in
            post.isSubscribed = true
        }
    }
    
    func postViewDidUnfollow(
        _ content: FormattedPost
    ) {
        updatePost { post in
            post.isSubscribed = false
        }
    }
    
    func postViewDidMarkAsCompleted(
        _ content: FormattedPost
    ) {
        updatePost { post in
            post.isFinished = true
        }
    }
    
    private func updatePost(
        _ update: (inout FormattedPost) -> Void
    ) {
        guard var post = postDetailVM.post else {
            return
        }
        
        update(&post)
        postDetailVM.post = post
    }
}

#Preview {
    NavigationStack {
        PostDetailScreen(
            postId: "preview-post-id"
        )
    }
}
