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
                VStack {
                    List(blockedUserVM.blockedUsers) { user in
                        HStack {
                            ProfilePicView(profilePic: user.profilePic)
                            
                            Text(user.name)
                        }
                    }
                }
            }
            
            if blockedUserVM.overlayError.0 {
                AYErrorAlert(message: blockedUserVM.overlayError.1, isErrorAlertPresented: $blockedUserVM.overlayError.0)
            }
        }
        .onAppear {
            Task {
                let token = try await authVM.getFirebaseToken()
                await blockedUserVM.getBockeUser(token: token)
            }
        }
        .navigationTitle("Blocked Users")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    BlockedUserScreen()
}
