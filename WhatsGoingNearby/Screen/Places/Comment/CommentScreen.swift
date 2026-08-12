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
    
    @State private var isLoadingComments = true
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
                        Comments()
                    }
                }
                
                if post.postSource == .publication {
                    CommentTextField()
                }
            }
            
            AYErrorAlert(
                message: commentVM.overlayError.1,
                isErrorAlertPresented: $commentVM.overlayError.0
            )
        }
        .task {
            await loadInitialComments()
        }
        .navigationTitle("Comments")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Comments
    
    @ViewBuilder
    private func Comments() -> some View {
        VStack(spacing: 0) {
            Disclaimer()
            
            Divider()
            
            if isLoadingComments {
                CommentsLoadingView()
            } else if commentVM.hasLoadedComments && commentVM.comments.isEmpty {
                EmptyCommentsView()
            } else {
                CommentsList()
            }
        }
    }
    
    @ViewBuilder
    private func CommentsList() -> some View {
        ForEach($commentVM.comments) { $comment in
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
                    commentVM.repliedComment = comment
                    commentIsFocused = true
                },
                location: $locationManager.location
            )
            .padding()
            
            Divider()
        }
    }
    
    // MARK: - Comments Loading
    
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
    
    // MARK: - Empty Comments
    
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
    private func CommentTextField() -> some View {
        VStack(spacing: 0) {
            if let comment = commentVM.repliedComment {
                HStack {
                    Button {
                        commentVM.repliedComment = nil
                    } label: {
                        HStack {
                            Text("Replying to \(comment.username)")
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
                    commentVM.repliedComment == nil
                        ? "Add a comment..."
                        : "Add a reply...",
                    text: $commentVM.newCommentText,
                    axis: .vertical
                )
                .padding(10)
                .background(
                    LinearGradient(
                        gradient: Gradient(
                            colors: [
                                Color.gray.opacity(0.1)
                            ]
                        ),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(20)
                .shadow(
                    color: .gray,
                    radius: 10
                )
                .focused($commentIsFocused)
                .onChange(of: commentVM.newCommentText) { newValue in
                    limitCommentLength(newValue)
                }
                
                if !commentVM.newCommentText.isEmpty {
                    Button {
                        commentIsFocused = false
                        
                        Task {
                            await postNewComment()
                        }
                    } label: {
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
    
    // MARK: - Initial Loading
    
    private func loadInitialComments() async {
        isLoadingComments = true
        
        do {
            let token = try await authVM.getFirebaseToken()
            
            await commentVM.getAllComments(
                publicationId: post.id,
                token: token
            )
            
        } catch {
            commentVM.overlayError = (
                true,
                LocalizedStringKey(error.localizedDescription)
            )
        }
        
        isLoadingComments = false
    }
    
    // MARK: - Comment Actions
    
    private func postNewComment() async {
        guard let location = locationManager.location else {
            return
        }
        
        do {
            let token = try await authVM.getFirebaseToken()
            
            await commentVM.postNewComment(
                publicationId: post.id,
                text: commentVM.newCommentText,
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                token: token
            )
            
        } catch {
            commentVM.overlayError = (
                true,
                LocalizedStringKey(error.localizedDescription)
            )
        }
    }
    
    private func deleteComment(commentId: String) async {
        do {
            let token = try await authVM.getFirebaseToken()
            
            await commentVM.deleteComment(
                commentId: commentId,
                token: token
            )
        } catch {
            commentVM.overlayError = (
                true,
                LocalizedStringKey(error.localizedDescription)
            )
        }
    }
    
    private func limitCommentLength(_ text: String) {
        guard text.count > maxCommentLength else {
            return
        }
        
        commentVM.newCommentText = String(
            text.prefix(maxCommentLength)
        )
    }
    
}

// MARK: - Post View Protocol

extension CommentScreen {
    
    func postViewDidLikePublication(
        _ content: FormattedPost
    ) {
        guard let likes = post.likes else {
            return
        }
        
        post.likes = likes + 1
        post.didLike = true
    }
    
    func postViewDidUnlikePublication(
        _ content: FormattedPost
    ) {
        guard let likes = post.likes else {
            return
        }
        
        post.likes = max(0, likes - 1)
        post.didLike = false
    }
    
    func postViewDidDeletePublication(
        _ content: FormattedPost
    ) {
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
        post.isSubscribed = true
    }
    
    func postViewDidUnfollow(
        _ content: FormattedPost
    ) {
        post.isSubscribed = false
    }
    
    func postViewDidMarkAsCompleted(
        _ content: FormattedPost
    ) {
        post.isFinished = true
    }
}
