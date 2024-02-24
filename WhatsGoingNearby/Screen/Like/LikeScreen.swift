//
//  LikeScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 22/02/24.
//

import SwiftUI

enum LikeScreenType {
    case publication
    case comment
}

struct LikeScreen: View {
    
    let id: String
    let type: LikeScreenType
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var likeVM = LikeViewModel()
    
    var body: some View {
        ZStack {
            if likeVM.isLoading {
                ProgressView()
            } else {
                if likeVM.users.isEmpty {
                    Text("No one has liked this post yet.")
                        .foregroundStyle(.gray)
                } else {
                    VStack {
                        List(likeVM.users) { user in
                            NavigationLink(destination: UserProfileScreen(userUid: user.userUid).environmentObject(authVM)) {
                                ProfilePicView(profilePic: user.profilePic)
                                
                                Text(user.name)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            
            AYErrorAlert(message: likeVM.overlayError.1, isErrorAlertPresented: $likeVM.overlayError.0)
        }
        .onAppear {
            if !likeVM.usersFetched {
                Task {
                    let token = try await authVM.getFirebaseToken()
                    if type == .publication {
                        await likeVM.getPublicationLikes(publicationId: id, token: token)
                    } else {
                        await likeVM.getCommentLikes(commentId: id, token: token)
                    }
                }
            }
        }
        .navigationTitle("Likes")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    LikeScreen(id: "", type: .publication)
}
