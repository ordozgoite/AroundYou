//
//  CommentScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 14/02/24.
//

import SwiftUI
import CoreLocation

struct CommentScreen: View {
    
    let postId: String
    private let maxCommentLength = 250
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var commentVM = CommentViewModel()
    @Binding var post: FormattedPost
    @Environment(\.presentationMode) var presentationMode
    @FocusState private var commentIsFocused: Bool
    @Binding var location: CLLocation?
    
    var body: some View {
        ZStack {
            VStack {
                ScrollView {
                    PostView(post: $post, location: $location) {
                        Task {
                            let token = try await authVM.getFirebaseToken()
                            await commentVM.deletePost(publicationId: postId, token: token) {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    } toggleFeedUpdate: { _ in }
                        .padding()
                    
                    Divider()
                    
                    Comments()
                        .opacity(post.type == .inactive ? 0.5 : 1)
                }
                
                CommentTextField()
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
    }
    
    //MARK: - Comments
    
    @ViewBuilder
    private func Comments() -> some View {
        VStack {
            ForEach($commentVM.comments) { $comment in
                CommentView(isPostFromRecipientUser: post.isFromRecipientUser, postType: post.type, comment: $comment, deleteComment: {
                    Task {
                        let token = try await authVM.getFirebaseToken()
                        await commentVM.deleteComment(commentId: comment.id, token: token)
                    }
                }, reply: {
                    commentIsFocused = true
                    commentVM.repliedComment = comment
                }, location: $location)
                .padding()
                Divider()
            }
        }
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
        if let location = location {
            let token = try await authVM.getFirebaseToken()
            
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            
            await commentVM.postNewComment(publicationId: postId, text: commentVM.newCommentText, latitude: latitude, longitude: longitude, token: token)
        }
    }
    
    private func startUpdatingComments() {
        commentVM.timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            Task {
                let token = try await authVM.getFirebaseToken()
                await commentVM.getAllComments(publicationId: postId, token: token)
            }
        }
        commentVM.timer?.fire()
    }
    
    private func stopTimer() {
        commentVM.timer?.invalidate()
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
