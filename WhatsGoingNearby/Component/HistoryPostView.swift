////
////  HistoryPostView.swift
////  WhatsGoingNearby
////
////  Created by Victor Ordozgoite on 16/02/24.
////
//
//import SwiftUI
//
//struct HistoryPostView: View {
//    
//    @EnvironmentObject var authVM: AuthenticationViewModel
//    @ObservedObject var feedVM: FeedViewModel
//    @Binding var post: FormattedPost
//    let deletePost: () -> ()
//    
//    var body: some View {
//        VStack {
//            HStack(alignment: .top) {
//                ProfilePic()
//                
//                VStack(alignment: .leading, spacing: 8) {
//                    HeaderView()
//                    
//                    TextView()
//                    
//                    InteractionsView()
//                }
//            }
//        }
//    }
//    
//    //MARK: - ProfilePic
//    
//    @ViewBuilder
//    private func ProfilePic() -> some View {
//        VStack {
//            NavigationLink(destination: UserProfileScreen(userUid: post.userUid).environmentObject(authVM)) {
//                ProfilePicView(profilePic: post.userProfilePic)
//            }
//            .buttonStyle(PlainButtonStyle())
//        }
//    }
//    
//    //MARK: - Header
//    
//    @ViewBuilder
//    private func HeaderView() -> some View {
//        HStack {
//            Text(post.userName ?? "Anonymous")
//                .fontWeight(.semibold)
//            
//            CircleTimerView(postDate: post.timestamp.timeIntervalSince1970InSeconds, expirationDate: post.expirationDate.timeIntervalSince1970InSeconds)
//            
//            Spacer()
//            
//            Menu {
//                if post.isFromRecipientUser {
//                    Button(role: .destructive, action: {
//                        deletePost()
//                    }) {
//                        Text("Delete Post")
//                        Image(systemName: "trash")
//                    }
//                }
//                
//                Button(role: .destructive, action: {}) {
//                    Text("Report Post")
//                    Image(systemName: "exclamationmark.bubble")
//                }
//            } label: {
//                Image(systemName: "ellipsis")
//                    .resizable()
//                    .aspectRatio(contentMode: .fit)
//                    .frame(width: 24, height: 24)
//                    .foregroundStyle(.gray)
//                    .padding([.trailing], 10)
//            }
//        }
//    }
//    
//    //MARK: - Text
//    
//    @ViewBuilder
//    private func TextView() -> some View {
//        Text(post.text)
//    }
//    
//    //MARK: - Interactions
//    
//    @ViewBuilder
//    private func InteractionsView() -> some View {
//        HStack(spacing: 32) {
//            HStack {
//                Image(systemName: post.didLike ? "heart.fill" : "heart")
//                    .foregroundColor(post.didLike ? .red : .gray)
//                    .onTapGesture {
//                        Task {
//                            let token = try await authVM.getFirebaseToken()
//                            if post.didLike {
//                                post.didLike = false
//                                post.likes -= 1
//                                await feedVM.unlikePublication(publicationId: post.id, token: token)
//                            } else {
//                                hapticFeedback()
//                                post.didLike = true
//                                post.likes += 1
//                                await feedVM.likePublication(publicationId: post.id, token: token)
//                            }
//                        }
//                    }
//                
//                Text(String(post.likes))
//                    .font(.subheadline)
//                    .foregroundColor(.gray)
//            }
//            HStack {
//                Image(systemName: "bubble.left")
//                    .foregroundColor(.gray)
//                
//                Text(String(post.comment))
//                    .font(.subheadline)
//                    .foregroundColor(.gray)
//            }
//            Spacer()
//        }
//    }
//    
//}
//
//#Preview {
//    HistoryPostView()
//}
