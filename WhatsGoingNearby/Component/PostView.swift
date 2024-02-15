//
//  PostView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import SwiftUI

struct PostView: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @ObservedObject var feedVM: FeedViewModel
    @Binding var post: FormattedPost
    let deletePost: () -> ()
    
    var body: some View {
        VStack {
            HStack(alignment: .top) {
                ProfilePicView()
                
                VStack(alignment: .leading, spacing: 8) {
                    HeaderView()
                    
                    TextView()
                    
                    InteractionsView()
                }
            }
        }
    }
    
    //MARK: - ProfilePic
    
    @ViewBuilder
    private func ProfilePicView() -> some View {
        VStack {
            if let imageUrl = post.userProfilePic {
                ProfilePictureView(imageURL: imageUrl)
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
            }
        }
    }
    
    //MARK: - Header
    
    @ViewBuilder
    private func HeaderView() -> some View {
        HStack {
            Text(post.userName ?? "Anonymous")
                .fontWeight(.semibold)
            
            CircleTimerView(postDate: post.timestamp.timeIntervalSince1970InSeconds, expirationDate: post.expirationDate.timeIntervalSince1970InSeconds)
            
            Spacer()
            
            Menu {
                if post.isFromRecipientUser {
                    Button(role: .destructive, action: {
                        deletePost()
                    }) {
                        Text("Delete Post")
                        Image(systemName: "trash")
                    }
                }
                
                Button(role: .destructive, action: {}) {
                    Text("Report Post")
                    Image(systemName: "exclamationmark.bubble")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(.gray)
                    .padding([.trailing], 8)
            }
        }
    }
    
    //MARK: - Text
    
    @ViewBuilder
    private func TextView() -> some View {
        Text(post.text)
    }
    
    //MARK: - Interactions
    
    @ViewBuilder
    private func InteractionsView() -> some View {
        HStack(spacing: 32) {
            HStack {
                Image(systemName: post.didLike ? "heart.fill" : "heart")
                    .foregroundColor(post.didLike ? .red : .gray)
                    .onTapGesture {
                        Task {
                            let token = try await authVM.getFirebaseToken()
                            if post.didLike {
                                post.didLike = false
                                post.likes -= 1
                                await feedVM.unlikePublication(publicationId: post.id, token: token)
                            } else {
                                post.didLike = true
                                post.likes += 1
                                await feedVM.likePublication(publicationId: post.id, token: token)
                            }
                        }
                    }
                
                Text(String(post.likes))
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            HStack {
                Image(systemName: "bubble.left")
                    .foregroundColor(.gray)
                
                Text(String(post.comment))
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
    }
    
}

#Preview {
    PostView(feedVM: FeedViewModel(), post: .constant(FormattedPost(
        id: "", userUid: "", userProfilePic: "https://www.bloomberglinea.com/resizer/PLUNbQCzVan6SFJ1RQ3CcBj6js8=/600x0/filters:format(webp):quality(75)/cloudfront-us-east-1.images.arcpublishing.com/bloomberglinea/S5ZMXTXZINE2JBQAV7MECJA7KM.jpg",
        userName: "Victor Ordozgoite",
        timestamp: Int(Date().timeIntervalSince1970), expirationDate: Int(Date().timeIntervalSince1970),
        text: "Alguém sabe quando o KFC vai ser inaugurado?? Já faz tempo que eles estão anunciando...", likes: 2, didLike: true, comment: 2, isFromRecipientUser: true)), deletePost: {})
    .environmentObject(AuthenticationViewModel())
}
