//
//  UserProfileScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 15/02/24.
//

import SwiftUI

struct UserProfileScreen: View {
    
    let userUid: String
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var userProfileVM = UserProfileViewModel()
    
    var body: some View {
        ZStack {
            VStack {
                if userProfileVM.isLoading {
                    ProgressView()
                } else {
                    ZStack {
                        VStack {
                            ProfileHeader()
                            Spacer()
                        }
                        
                        Warning()
                    }
                }
            }
            
            if userProfileVM.overlayError.0 {
                AYErrorAlert(message: userProfileVM.overlayError.1 , isErrorAlertPresented: $userProfileVM.overlayError.0)
            }
        }
        .onAppear {
            Task {
                let token = try await authVM.getFirebaseToken()
                await userProfileVM.getUserProfile(userUid: userUid, token: token)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    //MARK: - Profile Header
    
    @ViewBuilder
    private func ProfileHeader() -> some View {
        VStack {
            if let imageURL = userProfileVM.userProfile?.profilePic {
                URLImageView(imageURL: imageURL)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 128, height: 128)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundStyle(.gray)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 128, height: 128)
            }
            
            Text(userProfileVM.userProfile?.name ?? "")
                .font(.title)
                .fontWeight(.semibold)
            
            Text(userProfileVM.userProfile?.biography ?? "No bio.")
                .foregroundStyle(.gray)
        }
    }
    
    //MARK: - Warning
    
    @ViewBuilder
    private func Warning() -> some View {
        if let myId = authVM.user?.uid {
            if userUid == myId {
                Text("That's how people see you.")
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .fontWeight(.semibold)
                    .padding()
            } else {
                Text("You can't see other people's post history.")
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .fontWeight(.semibold)
                    .padding()
            }
        }
    }
}
