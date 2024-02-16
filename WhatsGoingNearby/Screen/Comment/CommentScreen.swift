//
//  CommentScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 14/02/24.
//

import SwiftUI

struct CommentScreen: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var commentVM = CommentViewModel()
    @ObservedObject var feedVM: FeedViewModel
    @Binding var post: FormattedPost
    @Environment(\.presentationMode) var presentationMode
    @FocusState private var commentIsFocused: Bool
    
    var body: some View {
        VStack {
            ScrollView {
                PostView(feedVM: feedVM, post: $post) {
                    Task {
                        let token = try await authVM.getFirebaseToken()
                        await commentVM.deletePost(publicationId: post.id, token: token) {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
                .padding()
                
                Divider()
                
                Comments()
            }
            
            CommentTextField()
        }
        .onAppear {
            startUpdatingComments()
        }
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    //MARK: - Comments
    
    @ViewBuilder
    private func Comments() -> some View {
        VStack {
            ForEach($commentVM.comments) { $comment in
                CommentView(comment: $comment) {
                    Task {
                        let token = try await authVM.getFirebaseToken()
                        await commentVM.deleteComment(commentId: comment.id, token: token)
                    }
                }
                .padding()
                Divider()
            }
        }
    }
    
    //MARK: - Comment Text Field
    
    @ViewBuilder
    private func CommentTextField() -> some View {
        HStack {
            TextField("Comment this post", text: $commentVM.newCommentText)
                .textFieldStyle(.roundedBorder)
                .focused($commentIsFocused)
            
            if commentVM.isPostingComment {
                ProgressView()
            } else {
                Button(action: {
                    Task {
                        let token = try await authVM.getFirebaseToken()
                        await commentVM.postNewComment(publicationId: post.id, text: commentVM.newCommentText, token: token)
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
    
    private func startUpdatingComments() {
        let timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            Task {
                let token = try await authVM.getFirebaseToken()
                await commentVM.getAllComments(publicationId: post.id, token: token)
            }
        }
        timer.fire()
    }
}

#Preview {
    CommentScreen(feedVM: FeedViewModel(), post: .constant(FormattedPost(
        id: "", userUid: "", userProfilePic: "https://www.bloomberglinea.com/resizer/PLUNbQCzVan6SFJ1RQ3CcBj6js8=/600x0/filters:format(webp):quality(75)/cloudfront-us-east-1.images.arcpublishing.com/bloomberglinea/S5ZMXTXZINE2JBQAV7MECJA7KM.jpg",
        userName: "Tim Cook",
        timestamp: Int(Date().timeIntervalSince1970), expirationDate: Int(Date().timeIntervalSince1970),
        text: "Alguém sabe quando lança o Apple Vision Pro?", likes: 2, didLike: true, comment: 2, isFromRecipientUser: true)))
}
