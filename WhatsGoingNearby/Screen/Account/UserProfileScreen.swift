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
    
    @State private var userProfile: UserProfile? = nil
    @State private var isLoading: Bool = false
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
            } else {
                VStack {
                    ProfileHeader()
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            Task {
                try await getUserProfile()
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    //MARK: - Profile Header
    
    @ViewBuilder
    private func ProfileHeader() -> some View {
        VStack {
            if let imageURL = userProfile?.profilePic {
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
            
            Text(userProfile?.name ?? "")
                .font(.title)
                .fontWeight(.semibold)
            
            Text(userProfile?.biography ?? "No bio.")
                .foregroundStyle(.gray)
        }
    }
    
    //MARK: - Auxiliary Methods
    
    private func getUserProfile() async throws {
        isLoading = true
        let token = try await authVM.getFirebaseToken()
        let response = await AYServices.shared.getUserProfile(userUid: userUid, token: token)
        isLoading = false
        
        switch response {
        case .success(let user):
            userProfile = user
        case .failure(let error):
            // Display error
            print("❌ Error: \(error)")
        }
    }
}
