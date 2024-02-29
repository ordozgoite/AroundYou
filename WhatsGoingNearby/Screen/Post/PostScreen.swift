//
//  NewCommentScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 29/02/24.
//

import SwiftUI
import CoreLocation

struct PostScreen: View {
    
    let postId: String
    private let maxCommentLength = 250
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var postVM = PostViewModel()
    @Environment(\.presentationMode) var presentationMode
    @FocusState private var commentIsFocused: Bool
    @Binding var location: CLLocation?
    
    var body: some View {
        ZStack {
            VStack {
                ScrollView {
                    if postVM.isPostFetched {
                        PostView(post: $postVM.post) {
                            Task {
                                let token = try await authVM.getFirebaseToken()
                                await postVM.deletePost(publicationId: postId, token: token) {
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }
                        }
                        .padding()
                        
                        Divider()
                    } else {
                        ProgressView()
                    }
                    
                    Comments()
                }
                
                CommentTextField()
            }
            
            AYErrorAlert(message: postVM.overlayError.1 , isErrorAlertPresented: $postVM.overlayError.0)
        }
        .onAppear {
            Task {
                try await getPublication()
            }
            startUpdatingComments()
        }
        .onDisappear {
            stopTimer()
        }
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    //MARK: - Comments
    
    @ViewBuilder
    private func Comments() -> some View {
        VStack {
            ForEach($postVM.comments) { $comment in
                CommentView(isPostFromRecipientUser: true, comment: $comment) { // mudar para valor dinâmico
                    Task {
                        let token = try await authVM.getFirebaseToken()
                        await postVM.deleteComment(commentId: comment.id, token: token)
                    }
                } reply: {
                    commentIsFocused = true
                    postVM.repliedComment = comment
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
            if let comment = postVM.repliedComment {
                HStack {
                    HStack {
                        Text("Replying to \(comment.userName)")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                        
                        Image(systemName: "xmark")
                            .scaleEffect(0.8)
                            .foregroundStyle(.blue)
                    }
                    .onTapGesture {
                        postVM.repliedComment = nil
                    }
                    
                    Spacer()
                }
                .padding(10)
            }
            
            HStack {
                TextField(postVM.repliedComment == nil ? "Add a comment... " : "Add a reply...", text: $postVM.newCommentText, axis: .vertical)
                    .padding(10)
                    .background(LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                    .cornerRadius(20)
                    .shadow(color: .gray, radius: 10)
                    .focused($commentIsFocused)
                    .onChange(of: postVM.newCommentText) { newValue in
                        if newValue.count > maxCommentLength {
                            postVM.newCommentText = String(newValue.prefix(maxCommentLength))
                        }
                    }
                
                if !postVM.newCommentText.isEmpty {
                    Button(action: {
                        commentIsFocused = false
                        Task {
                            let token = try await authVM.getFirebaseToken()
                            await postVM.postNewComment(publicationId: postId, text: postVM.newCommentText, token: token)
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
    
    private func getPublication() async throws {
        if let location = location {
            let token = try await authVM.getFirebaseToken()
            
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            
            await postVM.getPublication(publicationId: self.postId, latitude: latitude, longitude: longitude, token: token)
        }
    }
    
    private func startUpdatingComments() {
        postVM.timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            Task {
                let token = try await authVM.getFirebaseToken()
                await postVM.getAllComments(publicationId: postId, token: token)
            }
        }
        postVM.timer?.fire()
    }
    
    private func stopTimer() {
        postVM.timer?.invalidate()
    }
}
