//
//  CommentView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 14/02/24.
//

import SwiftUI

struct CommentView: View {
    
    let isPostFromRecipientUser: Bool
    @EnvironmentObject var authVM: AuthenticationViewModel
    @Binding var comment: FormattedComment
    let deleteComment: () -> ()
    @State private var isReportScreenPresented: Bool = false
    @State private var isLikeScreenDisplayed: Bool = false
    var reply: () -> ()
    
    var body: some View {
        VStack {
            HStack(alignment: .top) {
                ProfilePic()
                
                VStack(alignment: .leading) {
                    HeaderView()
                    
                    TextView()
                
                    Footer()
                }
            }
            NavigationLink(
                destination: ReportScreen(reportedUserUid: comment.userUid, publicationId: nil, commentId: comment.id).environmentObject(authVM),
                isActive: $isReportScreenPresented,
                label: { EmptyView() }
            )
            
            NavigationLink(
                destination: LikeScreen(id: comment.id, type: .comment).environmentObject(authVM),
                isActive: $isLikeScreenDisplayed,
                label: { EmptyView() }
            )
        }
    }
    
    //MARK: - ProfilePic
    
    @ViewBuilder
    private func ProfilePic() -> some View {
        VStack {
            NavigationLink(destination: UserProfileScreen(userUid: comment.userUid).environmentObject(authVM)) {
                ProfilePicView(profilePic: comment.userProfilePic)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    //MARK: - Header
    
    @ViewBuilder
    private func HeaderView() -> some View {
        HStack {
            Text(comment.userName)
                .fontWeight(.semibold)
                .fixedSize(horizontal: false, vertical: true)
            
            Reply()
            
            Spacer()
            
            Menu {
                if comment.isFromRecipientUser || isPostFromRecipientUser {
                    Button(role: .destructive, action: {
                        deleteComment()
                    }) {
                        Text("Delete Comment")
                        Image(systemName: "trash")
                    }
                }
                
                if !comment.isFromRecipientUser {
                    Button(action: {
                        isReportScreenPresented = true
                    }) {
                        Text("Report Comment")
                            .foregroundStyle(.gray)
                        Image(systemName: "exclamationmark.bubble")
                            .foregroundStyle(.gray)
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)
                    .foregroundStyle(.gray)
                    .padding([.trailing], 10)
            }
        }
    }
    
    //MARK: - Text
    
    @ViewBuilder
    private func TextView() -> some View {
        Text(comment.text)
    }
    
    //MARK: - Reply
    
    @ViewBuilder
    private func Reply() -> some View {
        if let name = comment.repliedUserFirstName {
            HStack {
                Image(systemName: "arrowtriangle.forward.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 10, height: 10)
                    .foregroundStyle(.gray)
                
                Text("\(name)")
                    .foregroundStyle(.gray)
                    .font(.subheadline)
            }
            .scaleEffect(0.9)
        }
    }
    
    //MARK: - Footer
    
    @ViewBuilder
    private func Footer() -> some View {
        HStack(spacing: 32) {
            HStack {
                Image(systemName: comment.didLike ? "heart.fill" : "heart")
                    .foregroundColor(comment.didLike ? .red : .gray)
                    .onTapGesture {
                        Task {
                            let token = try await authVM.getFirebaseToken()
                            if comment.didLike {
                                comment.didLike = false
                                comment.likes -= 1
                                await unlikeComment(commentId: comment.id, token: token)
                            } else {
                                hapticFeedback()
                                comment.didLike = true
                                comment.likes += 1
                                await likeComment(commentId: comment.id, token: token)
                            }
                        }
                    }
                
                Text(String(comment.likes))
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .onTapGesture {
                        isLikeScreenDisplayed = true
                    }
            }
            
            Text(comment.date.timeAgoDisplay())
                .foregroundStyle(.gray)
                .font(.subheadline)
            
            if comment.userUid != LocalState.currentUserUid {
                HStack {
                    Image(systemName: "arrow.turn.up.left")
                        .foregroundStyle(.gray)
                    
                    Text("Reply")
                        .foregroundStyle(.gray)
                        .font(.subheadline)
                }
                .onTapGesture {
                    reply()
                }
            }
            
            Spacer()
        }
        .padding(.top, 1)
    }
    
    //MARK: - Auxiliary Methods
    
    private func likeComment(commentId: String, token: String) async {
        let result = await AYServices.shared.likeComment(commentId: commentId, token: token)
        
        switch result {
        case .success:
            print("❤️ Publication liked!")
        case .failure(let error):
            print("❌ Error: \(error)")
        }
    }
    
    private func unlikeComment(commentId: String, token: String) async {
        let result = await AYServices.shared.unlikeComment(commentId: commentId, token: token)
        
        switch result {
        case .success:
            print("💔 Publication unliked!")
        case .failure(let error):
            print("❌ Error: \(error)")
        }
    }
}

#Preview {
    CommentView(isPostFromRecipientUser: true, comment: .constant(FormattedComment(
        id: "", userUid: "", publicationId: "", text: "Acho que mês que vem",
        timestamp: Int(Date().timeIntervalSince1970),
        userProfilePic: "https://www.bloomberglinea.com/resizer/PLUNbQCzVan6SFJ1RQ3CcBj6js8=/600x0/filters:format(webp):quality(75)/cloudfront-us-east-1.images.arcpublishing.com/bloomberglinea/S5ZMXTXZINE2JBQAV7MECJA7KM.jpg",
        userName: "Victor Ordozgoite", isFromRecipientUser: true, didLike: true, likes: 5, repliedUserName: "Dean Batista")), deleteComment: {}, reply: {})
    .environmentObject(AuthenticationViewModel())
}
