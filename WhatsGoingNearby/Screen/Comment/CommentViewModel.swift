//
//  CommentViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 16/02/24.
//

import Foundation

@MainActor
class CommentViewModel: ObservableObject {
    
    @Published var post: FormattedPost?
    @Published var comments: [FormattedComment] = []
    @Published var newCommentText: String = ""
    @Published var isPostingComment: Bool = false
    
    func getAllComments(publicationId: String, token: String) async {
        let response = await AYServices.shared.getAllCommentsByPublication(publicationId: publicationId, token: token)
        
        switch response {
        case .success(let comments):
            self.comments = comments
        case .failure(let error):
            // Display error
            print("❌ Error: \(error)")
        }
    }
    
    func postNewComment(publicationId: String, text: String, token: String) async {
        newCommentText = ""
        
        isPostingComment = true
        let response = await AYServices.shared.postNewComment(publicationId: publicationId, text: text, token: token)
        isPostingComment = false
        
        switch response {
        case .success:
            //            post.comment += 1
            await getAllComments(publicationId: publicationId, token: token)
        case .failure(let error):
            // Display error
            print("❌ Error: \(error)")
        }
    }
    
    func deleteComment(commentId: String, token: String) async {
        let response = await AYServices.shared.deleteComment(commentId: commentId, token: token)
        
        switch response {
        case .success:
            popComment(commentId: commentId)
        case .failure(let error):
            // Display error
            print("❌ Error: \(error)")
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
        case .failure(let error):
            // Display error
            print("❌ Error: \(error)")
        }
    }
    
}
