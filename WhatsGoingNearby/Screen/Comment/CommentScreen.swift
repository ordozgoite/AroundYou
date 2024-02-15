//
//  CommentScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 14/02/24.
//

import SwiftUI

struct CommentScreen: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @ObservedObject var feedVM: FeedViewModel
    @Binding var post: FormattedPost
    @Environment(\.presentationMode) var presentationMode
    
    @FocusState private var commentIsFocused: Bool
    
    @State private var comments: [FormattedComment] = []
    @State private var isLoadingComments: Bool = false
    @State private var newCommentText: String = ""
    @State private var isPostingComment: Bool = false
    
    var body: some View {
        VStack {
            ScrollView {
                PostView(feedVM: feedVM, post: $post) {
                    Task {
                        try await deletePost()
                    }
                }
                    .padding()
                
                Divider()
                
                Comments()
            }
            
            CommentTextField()
        }
        .onAppear {
            Task {
                try await getAllComments()
            }
        }
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    //MARK: - Comments
    
    @ViewBuilder
    private func Comments() -> some View {
        VStack {
            if isLoadingComments {
                ProgressView()
            } else {
                ForEach($comments) { $comment in
                    CommentView(comment: $comment) { 
                        Task {
                            try await deleteComment(commentId: comment.id)
                        }
                    }
                        .padding()
                    Divider()
                }
            }
        }
    }
    
    //MARK: - Comment Text Field
    
    @ViewBuilder
    private func CommentTextField() -> some View {
        HStack {
            TextField("Comment this post", text: $newCommentText)
                .textFieldStyle(.roundedBorder)
                .focused($commentIsFocused)
            
            if isPostingComment {
                ProgressView()
            } else {
                Button(action: {
                    Task {
                        try await postNewComment(text: newCommentText)
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
    
    //MARK: - Auxiliary methods
    
    private func getAllComments() async throws {
        isLoadingComments = true
        let token = try await authVM.getFirebaseToken()
        let response = await AYServices.shared.getAllCommentsByPublication(publicationId: post.id, token: token)
        isLoadingComments = false
        
        switch response {
        case .success(let comments):
            self.comments = comments
        case .failure(let error):
            // Display error
            print("❌ Error: \(error)")
        }
    }
    
    private func postNewComment(text: String) async throws {
        commentIsFocused = false
        newCommentText = ""
        
        isPostingComment = true
        let token = try await authVM.getFirebaseToken()
        let response = await AYServices.shared.postNewComment(publicationId: post.id, text: text, token: token)
        isPostingComment = false
        
        switch response {
        case .success:
            post.comment += 1
            try await getAllComments()
        case .failure(let error):
            // Display error
            print("❌ Error: \(error)")
        }
    }
    
    private func deleteComment(commentId: String) async throws {
        let token = try await authVM.getFirebaseToken()
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
    
    private func deletePost() async throws {
        let token = try await authVM.getFirebaseToken()
        let response = await AYServices.shared.deletePublication(publicationId: post.id, token: token)
        
        switch response {
        case .success:
            presentationMode.wrappedValue.dismiss()
        case .failure(let error):
            // Display error
            print("❌ Error: \(error)")
        }
    }
}

#Preview {
    CommentScreen(feedVM: FeedViewModel(), post: .constant(FormattedPost(
        id: "", userUid: "", userProfilePic: "https://www.bloomberglinea.com/resizer/PLUNbQCzVan6SFJ1RQ3CcBj6js8=/600x0/filters:format(webp):quality(75)/cloudfront-us-east-1.images.arcpublishing.com/bloomberglinea/S5ZMXTXZINE2JBQAV7MECJA7KM.jpg",
        userName: "Tim Cook",
        timestamp: Int(Date().timeIntervalSince1970),
        text: "Alguém sabe quando lança o Apple Vision Pro?", likes: 2, didLike: true, comment: 2, isFromRecipientUser: true)))
}
