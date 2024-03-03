//
//  BlockedUserScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 18/02/24.
//

import SwiftUI

struct BlockedUserScreen: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var blockedUserVM = BlockedUserViewModel()
    
    var body: some View {
        ZStack {
            if blockedUserVM.isLoading {
                ProgressView()
            } else {
                if blockedUserVM.blockedUsers.isEmpty {
                    Text("You haven't blocked any users.")
                        .foregroundStyle(.gray)
                } else {
                    VStack {
                        List(blockedUserVM.blockedUsers) { user in
                            HStack {
                                ProfilePicView(profilePic: user.profilePic)
                                
                                Text(user.username)
                            }
                            .onTapGesture {
                                blockedUserVM.selectedUser = user
                                blockedUserVM.isUnblockAlertDisplayed = true
                            }
                        }
                    }
                }
            }
            
            AYErrorAlert(message: blockedUserVM.overlayError.1, isErrorAlertPresented: $blockedUserVM.overlayError.0)
        }
        .onAppear {
            Task {
                let token = try await authVM.getFirebaseToken()
                await blockedUserVM.getBockeUser(token: token)
            }
        }
        .alert(isPresented: $blockedUserVM.isUnblockAlertDisplayed) {
            Alert(
                title: Text("Unblock User"),
                message: Text("This user will be able to see your posts and profile, and you will be able to see this user's posts and profile."),
                primaryButton: .destructive(Text("Unblock")) {
                    Task {
                        if let blockedUserUid = blockedUserVM.selectedUser?.userUid {
                            let token = try await authVM.getFirebaseToken()
                            await blockedUserVM.unblockUser(blockedUserUid: blockedUserUid, token: token)
                        }
                    }
                },
                secondaryButton: .cancel(Text("Cancel")) {}
            )
        }
        .navigationTitle("Blocked Users")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    BlockedUserScreen()
}
