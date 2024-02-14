//
//  PostView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import SwiftUI

// Post Info:
// User profile pic
// User name
// Post timestamp
// Post text
// Post comments number
// Post likes number

struct PostData: Identifiable {
    let id = UUID()
    let userProfilePic: String
    let userName: String
    let timestamp: Date
    let text: String
    let commentsNumber: Int
    let likesNumber: Int
}

struct PostView: View {
    
    let post: PostData
    @State var didLikePost: Bool = false
    
    var body: some View {
        VStack {
            HStack(alignment: .top) {
                ProfilePicView()
                
                VStack(spacing: 8) {
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
            Image("shaq")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 64, height: 64)
                .clipShape(Circle())
        }
    }
    
    //MARK: - Header
    
    @ViewBuilder
    private func HeaderView() -> some View {
        HStack {
            Text(post.userName)
                .fontWeight(.semibold)
            
            Text(post.timestamp.convertToMinutesAgo())
                .font(.subheadline)
                .foregroundStyle(.gray)
            
            Spacer()
            
            Menu {
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
                Image(systemName: didLikePost ? "heart.fill" : "heart")
                    .foregroundColor(didLikePost ? .red : .gray)
                    .onTapGesture {
                        didLikePost.toggle()
                    }
                
                Text(String(post.likesNumber))
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            HStack {
                Image(systemName: "bubble.left")
                    .foregroundColor(.gray)
                    .onTapGesture {
                        // open comments
                    }
                
                Text(String(post.commentsNumber))
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
    }
    
}

#Preview {
    PostView(post: PostData(
        userProfilePic: "",
        userName: "Victor Ordozgoite",
        timestamp: Date(),
        text: "Alguém sabe quando o KFC vai ser inaugurado?? Já faz tempo que eles estão anunciando...",
        commentsNumber: 1,
        likesNumber: 3))
}
