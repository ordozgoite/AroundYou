//
//  PostDetailViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 03/08/26.
//

import Foundation
import SwiftUI

@MainActor
final class PostDetailViewModel: ObservableObject {
    
    @Published var post: FormattedPost?
    @Published var comments: [FormattedComment] = []
    
    @Published var newCommentText: String = ""
    @Published var repliedComment: FormattedComment?
    
    @Published var isLoadingPost = true
    @Published var isLoadingComments = false
    @Published var hasLoadedComments = false
    @Published var isPostingComment = false
    
    @Published var overlayError: (Bool, LocalizedStringKey) = (false, "")
    
    // MARK: - Post
    
    func getPost(
        postId: String,
        latitude: Double,
        longitude: Double,
        token: String
    ) async {
        isLoadingPost = true
        
        defer {
            isLoadingPost = false
        }
        
        let response = await AYServices.shared.getPublication(
            publicationId: postId,
            latitude: latitude,
            longitude: longitude,
            token: token
        )
        
        switch response {
        case .success(let publication):
            post = publication
            
        case .failure:
            overlayError = (
                true,
                ErrorMessage.getPostsErrorMessage
            )
        }
    }
    
    // MARK: - Comments
    
    func getAllComments(
        publicationId: String,
        token: String,
        showLoading: Bool = false
    ) async {
        if showLoading {
            isLoadingComments = true
        }
        
        defer {
            if showLoading {
                isLoadingComments = false
            }
        }
        
        let response = await AYServices.shared
            .getAllCommentsByPublication(
                publicationId: publicationId,
                token: token
            )
        
        switch response {
        case .success(let comments):
            self.comments = comments
            hasLoadedComments = true
            
        case .failure:
            if !hasLoadedComments {
                overlayError = (
                    true,
                    ErrorMessage.getAllComments
                )
            }
        }
    }
    
    func postNewComment(
        publicationId: String,
        text: String,
        latitude: Double,
        longitude: Double,
        token: String
    ) async {
        let comment = CommentDTO(
            publicationId: publicationId,
            text: text,
            repliedUserUid: repliedComment?.userUid,
            repliedUserUsername: repliedComment?.username
        )
        
        newCommentText = ""
        repliedComment = nil
        isPostingComment = true
        
        let response = await AYServices.shared.postNewComment(
            comment: comment,
            latitude: latitude,
            longitude: longitude,
            token: token
        )
        
        isPostingComment = false
        
        switch response {
        case .success:
            await getAllComments(
                publicationId: publicationId,
                token: token
            )
            
        case .failure(let error):
            if error == .forbidden {
                overlayError = (
                    true,
                    ErrorMessage.commentDistanceLimitExceededErrorMessage
                )
            } else {
                overlayError = (
                    true,
                    ErrorMessage.postComment
                )
            }
        }
    }
    
    func deleteComment(
        commentId: String,
        token: String
    ) async {
        let response = await AYServices.shared.deleteComment(
            commentId: commentId,
            token: token
        )
        
        switch response {
        case .success:
            popComment(commentId: commentId)
            
        case .failure:
            overlayError = (
                true,
                ErrorMessage.deleteComment
            )
        }
    }
    
    private func popComment(commentId: String) {
        comments.removeAll {
            $0.id == commentId
        }
    }
    
    // MARK: - Delete Post
    
    func deletePost(
        publicationId: String,
        token: String,
        dismissScreen: () -> Void
    ) async {
        let response = await AYServices.shared.deletePublication(
            publicationId: publicationId,
            token: token
        )
        
        switch response {
        case .success:
            dismissScreen()
            
        case .failure:
            overlayError = (
                true,
                ErrorMessage.deletePost
            )
        }
    }
    
}
