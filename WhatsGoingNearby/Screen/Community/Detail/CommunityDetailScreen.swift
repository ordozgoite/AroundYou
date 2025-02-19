//
//  CommunityDetailScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 18/02/25.
//

import SwiftUI

struct CommunityDetailScreen: View {
    
    let communityId: String
    let communityName: String
    let communityImageUrl: String?
    let isOwner: Bool
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var communityDetailVM = CommunityDetailViewModel()
    
    var body: some View {
        Form {
            Header()
            
            // TODO: Add Description
            
            if communityDetailVM.hasFetchedCommunityInfo {
                if isOwner {
                    UserRequests()
                }
                
                Members()
                
                // TODO: Add Location on map
            }
            
            LeaveButton()
            
            if isOwner {
                DeleteButton()
            }
        }
        .navigationTitle("Community Info")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                try await getCommunityInfo()
            }
        }
    }
    
    // MARK: - Header
    
    @ViewBuilder
    private func Header() -> some View {
        Section {
            VStack {
                HStack {
                    Spacer()
                    CommunityImageView(imageUrl: communityImageUrl, size: 150)
                    Spacer()
                }
                
                Text(communityName)
                    .font(.title)
                    .bold()
            }
        }
        .listRowBackground(Color(.systemGroupedBackground))
    }
    
    // MARK: - User Requests
    
    @ViewBuilder
    private func UserRequests() -> some View {
        if let requests = communityDetailVM.joinRequests {
            if !requests.isEmpty {
                Section {
                    ForEach(requests, id: \.self) { request in
                        HStack {
                            ProfilePicView(profilePic: request.profilePic, size: 50)
                            
                            Text(request.username)
                                .font(.title3)
                                .bold()
                            
                            Spacer()
                            
                            Button("Approve") {
                                // Aprove Join Request
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                } header: {
                    Text("\(String(requests.count)) request(s)")
                } footer: {
                    Text("These users want to join your community. Approve their request or ignore it.")
                }
            }
        }
    }
    
    // MARK: - Members
    
    @ViewBuilder
    private func Members() -> some View {
        Section {
            ForEach(communityDetailVM.members, id: \.self) { member in
                HStack {
                    ProfilePicView(profilePic: member.profilePic, size: 50)
                    
                    Text(member.username)
                        .font(.title3)
                        .bold()
                    
                    Spacer()
                    
                    if member.userUid == communityDetailVM.communityOwnerUid {
                        Text("admin")
                            .foregroundStyle(.gray)
                    }
                }
            }
        } header: {
            Text("\(String(communityDetailVM.members.count)) members")
        }
    }
    
    // MARK: - Leave Button
    
    @ViewBuilder
    private func LeaveButton() -> some View {
        Section {
            Button(role: .destructive) {
                // Leave Community
            } label: {
                Label("Leave Community", systemImage: "rectangle.portrait.and.arrow.right")
                    .foregroundStyle(isOwner ? .gray : .red)
            }
            .disabled(isOwner)
        } footer: {
            if isOwner {
                Text("You are the admin of this community and cannot leave it.")
            }
        }
    }
    
    // MARK: - Delete Button
    
    @ViewBuilder
    private func DeleteButton() -> some View {
        Section {
            Button(role: .destructive) {
                // Delete Community
            } label: {
                Label("Delete Community", systemImage: "trash")
                    .foregroundStyle(.red)
            }
        } footer: {
            Text("Deleting this community will permanently remove it for all members without prior notice. This action cannot be undone.")
        }
    }
}

// MARK: - Private Methods

extension CommunityDetailScreen {
    private func getCommunityInfo() async throws {
        let token = try await authVM.getFirebaseToken()
        await communityDetailVM.getCommunityInfo(communityId: self.communityId, token: token)
    }
}

#Preview {
    CommunityDetailScreen(communityId: UUID().uuidString, communityName: "Jogadores de Catan", communityImageUrl: nil, isOwner: true)
}
