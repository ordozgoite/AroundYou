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
    
    var body: some View {
        VStack {
            HStack(alignment: .top) {
                ProfilePic()
                
                VStack(alignment: .leading, spacing: 8) {
                    HeaderView()
                    
                    TextView()
                }
            }
            NavigationLink(
                destination: ReportScreen(reportedUserUid: comment.userUid, publicationId: nil, commentId: comment.id).environmentObject(authVM),
                isActive: $isReportScreenPresented,
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
            Text(comment.userName ?? "")
                .fontWeight(.semibold)
                .fixedSize(horizontal: false, vertical: true)
            
            Text(comment.date.timeAgoDisplay())
                .foregroundStyle(.gray)
                .font(.subheadline)
            
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
                    Button(role: .destructive, action: {
                        isReportScreenPresented = true
                    }) {
                        Text("Report Post")
                        Image(systemName: "exclamationmark.bubble")
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
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
    
}

#Preview {
    CommentView(isPostFromRecipientUser: true, comment: .constant(FormattedComment(
        id: "", userUid: "", publicationId: "", text: "Alguém sabe quando o KFC vai ser inaugurado?? Já faz tempo que eles estão anunciando...",
        timestamp: Int(Date().timeIntervalSince1970),
        userProfilePic: "https://www.bloomberglinea.com/resizer/PLUNbQCzVan6SFJ1RQ3CcBj6js8=/600x0/filters:format(webp):quality(75)/cloudfront-us-east-1.images.arcpublishing.com/bloomberglinea/S5ZMXTXZINE2JBQAV7MECJA7KM.jpg",
        userName: "Victor Ordozgoite", isFromRecipientUser: true)), deleteComment: {})
    .environmentObject(AuthenticationViewModel())
}
