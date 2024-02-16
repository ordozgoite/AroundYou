//
//  CommentScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 14/02/24.
//

import SwiftUI

struct CommentScreen: View {
    
    let postId: String
    private let maxCommentLength = 250
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var commentVM = CommentViewModel()
    @ObservedObject var feedVM: FeedViewModel
    @Binding var post: FormattedPost
    @Environment(\.presentationMode) var presentationMode
    @FocusState private var commentIsFocused: Bool
    
    var body: some View {
        ZStack {
            VStack {
                ScrollView {
                    PostView(feedVM: feedVM, post: $post) {
                        Task {
                            let token = try await authVM.getFirebaseToken()
                            await commentVM.deletePost(publicationId: postId, token: token) {
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
            
            if commentVM.overlayError.0 {
                AYErrorAlert(message: commentVM.overlayError.1 , isErrorAlertPresented: $commentVM.overlayError.0)
            }
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
        VStack {
            if commentIsFocused {
                HStack {
                    Text("Answering " + (post.userName ?? ""))
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                    Spacer()
                    Text("\(commentVM.newCommentText.count)/250")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }
                .padding([.leading, .trailing], 10)
            }
            HStack {
                TextField("Comment this post", text: $commentVM.newCommentText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .focused($commentIsFocused)
                    .onChange(of: commentVM.newCommentText) { newValue in
                        if newValue.count > maxCommentLength {
                            commentVM.newCommentText = String(newValue.prefix(maxCommentLength))
                        }
                    }
                
                if commentVM.isPostingComment {
                    ProgressView()
                } else {
                    Button(action: {
                        commentIsFocused = false
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
    }
    
    //MARK: - Auxiliary methods
    
    private func startUpdatingComments() {
        let timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            Task {
                let token = try await authVM.getFirebaseToken()
                await commentVM.getAllComments(publicationId: postId, token: token)
            }
        }
        timer.fire()
    }
}

#Preview {
    CommentScreen(postId: "", feedVM: FeedViewModel(), post: .constant(FormattedPost(
        id: "", userUid: "", userProfilePic: "https://www.bloomberglinea.com/resizer/PLUNbQCzVan6SFJ1RQ3CcBj6js8=/600x0/filters:format(webp):quality(75)/cloudfront-us-east-1.images.arcpublishing.com/bloomberglinea/S5ZMXTXZINE2JBQAV7MECJA7KM.jpg",
        userName: "Tim Cook",
        timestamp: Int(Date().timeIntervalSince1970), expirationDate: Int(Date().timeIntervalSince1970),
        text: "Alguém sabe quando lança o Apple Vision Pro?", likes: 2, didLike: true, comment: 2, isFromRecipientUser: true)))
}
