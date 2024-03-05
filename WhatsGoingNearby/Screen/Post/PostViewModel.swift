//
//  PostViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 29/02/24.
//

import Foundation
import SwiftUI

@MainActor
class PostViewModel: ObservableObject {
    
    @Published var post: FormattedPost = FormattedPost(id: "", userUid: "", userProfilePic: nil, username: "", timestamp: 0, expirationDate: 0, text: "", likes: 0, didLike: false, comment: 0, latitude: nil, longitude: nil, distanceToMe: nil, isFromRecipientUser: false, isLocationVisible: false, isSubscribed: false)
    
    @Published var comments: [FormattedComment] = []
    @Published var newCommentText: String = ""
    @Published var repliedComment: FormattedComment?
    @Published var isPostingComment: Bool = false
    @Published var isLoadingPost: Bool = false
    @Published var isPostFetched: Bool = false
    
    @Published var overlayError: (Bool, LocalizedStringKey) = (false, "")
    @Published var timer: Timer?
    
    func getPublication(publicationId: String, latitude: Double, longitude: Double, token: String) async {
        isLoadingPost = true
        let result = await AYServices.shared.getPublication(publicationId: publicationId, latitude: latitude, longitude: longitude, token: token)
        isLoadingPost = false
        
        switch result {
        case .success(let post):
            self.post = post
            isPostFetched = true
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
    }
    
    func getAllComments(publicationId: String, token: String) async {
        let response = await AYServices.shared.getAllCommentsByPublication(publicationId: publicationId, token: token)
        
        switch response {
        case .success(let comments):
            self.comments = comments
        case .failure(let error):
            print("❌ Error: \(error)")
        }
    }
    
    func postNewComment(publicationId: String, text: String, latitude: Double, longitude: Double, token: String) async {
        let comment = CommentDTO(publicationId: publicationId, text: text, repliedUserUid: repliedComment?.userUid, repliedUserUsername: repliedComment?.username)
        
        newCommentText = ""
        repliedComment = nil
        
        isPostingComment = true
        let response = await AYServices.shared.postNewComment(comment: comment, latitude: latitude, longitude: longitude, token: token)
        isPostingComment = false
        
        switch response {
        case .success:
            await getAllComments(publicationId: publicationId, token: token)
        case .failure(let error):
            if error == .forbidden {
                overlayError = (true, ErrorMessage.distanceLimitExceededMessage)
            } else {
                overlayError = (true, ErrorMessage.defaultErrorMessage)
            }
        }
    }
    
    func deleteComment(commentId: String, token: String) async {
        let response = await AYServices.shared.deleteComment(commentId: commentId, token: token)
        
        switch response {
        case .success:
            popComment(commentId: commentId)
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
    }
    
    private func popComment(commentId: String) {
        comments.removeAll { $0.id == commentId }
    }
    
    func deletePost(publicationId: String, token: String, dismissScreen: () -> ()) async  {
        let response = await AYServices.shared.deletePublication(publicationId: publicationId, token: token)
        
        switch response {
        case .success:
            dismissScreen()
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
    }
    
}
