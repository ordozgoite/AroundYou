//
//  LikeScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 22/02/24.
//

import SwiftUI

struct LikeScreen: View {
    
    let publicationId: String
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
                            HStack {
                                ProfilePicView(profilePic: user.profilePic)
                                
                                Text(user.name)
                            }
                            .onTapGesture {
                                // Go to user profile
                            }
                        }
                    }
                }
            }
            
            if likeVM.overlayError.0 {
                AYErrorAlert(message: likeVM.overlayError.1, isErrorAlertPresented: $likeVM.overlayError.0)
            }
        }
        .onAppear {
            Task {
                let token = try await authVM.getFirebaseToken()
                await likeVM.getPublicationLikes(publicationId: publicationId, token: token)
            }
        }
        .navigationTitle("Likes")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    LikeScreen(publicationId: "")
}
