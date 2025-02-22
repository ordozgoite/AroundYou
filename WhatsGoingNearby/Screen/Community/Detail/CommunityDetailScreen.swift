//
//  CommunityDetailScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 18/02/25.
//

import SwiftUI

struct CommunityDetailScreen: View {
    
    @State var community: FormattedCommunity
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var communityDetailVM = CommunityDetailViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Form {
            Header()
            
            Description()
            
            if communityDetailVM.hasFetchedCommunityInfo {
                if community.isOwner {
                    UserRequests()
                }
                
                Members()
                
                Location()
            }
            
            LeaveButton()
            
            if community.isOwner {
                DeleteButton()
            }
        }
        .navigationTitle("Community Info")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    communityDetailVM.isEditCommunityViewDisplayed = true
                }
            }
        }
        .onAppear {
            Task {
                try await getCommunityInfo()
            }
        }
        .sheet(isPresented: $communityDetailVM.isEditCommunityViewDisplayed) {
            EditCommunityView(
                communityId: self.community.id,
                prevCommunityName: self.community.name,
                prevCommunityImageUrl: self.community.imageUrl, updateCommunityInfo: {
                    updateCommunityInfo()
                },
                communityDetailVM: communityDetailVM,
                isViewDisplayed: $communityDetailVM.isEditCommunityViewDisplayed
            )
            .environmentObject(authVM)
            .interactiveDismissDisabled(true)
        }
    }
    
    // MARK: - Header
    
    @ViewBuilder
    private func Header() -> some View {
        Section {
            VStack {
                HStack {
                    ZStack {
                        CircleTimerView(postDate: community.createdAt.timeIntervalSince1970InSeconds, expirationDate: community.expirationDate.timeIntervalSince1970InSeconds, size: 158)
                        CommunityImageView(imageUrl: community.imageUrl, size: 150)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                
                Text(community.name)
                    .font(.title)
                    .bold()
            }
        }
        .listRowBackground(Color(.systemGroupedBackground))
    }
    
    // MARK: - Description
    
    @ViewBuilder
    private func Description() -> some View {
        Section {
            if let description = community.description {
                HStack {
                    Text(description)
                    
                    Spacer()
                    
                    if community.isOwner {
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.gray)
                    }
                }
                .onTapGesture {
                    if community.isOwner {
                        communityDetailVM.isEditDescriptionViewDisplayed = true
                    }
                }
            } else {
                if community.isOwner {
                    Button("Add Group Description") {
                        communityDetailVM.isEditDescriptionViewDisplayed = true
                    }
                }
            }
        }
        .sheet(isPresented: $communityDetailVM.isEditDescriptionViewDisplayed) {
            EditCommunityDescriptionView(
                communityId: self.community.id,
                previousDescription: self.community.description ?? "",
                updateCommunityDescription: { newDescription in
                    updateCommunityDescription(newDescription)
                }, communityDetailVM: communityDetailVM,
                isViewDisplayed: $communityDetailVM.isEditDescriptionViewDisplayed
            )
            .environmentObject(authVM)
            .interactiveDismissDisabled(true)
        }
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
                            
                            if communityDetailVM.isApprovingUserToCommunity.0 && communityDetailVM.isApprovingUserToCommunity.1 == request.userUid {
                                ProgressView()
                            } else {
                                Button("Approve") {
                                    Task {
                                        try await approveUser(request)
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                            }
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
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    if community.isOwner && member.userUid != communityDetailVM.communityOwnerUid {
                        Button(role: .destructive) {
                            Task {
                                try await deleteMember(member)
                            }
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }
                }
            }
        } header: {
            Text("\(String(communityDetailVM.members.count)) member(s)")
        }
    }
    
    // MARK: - Location
    
    @ViewBuilder
    private func Location() -> some View {
        if let latitude = community.latitude, let longitude = community.longitude {
            Section {
                ZStack {
                    MapView(latitude: latitude, longitude: longitude)
                        .frame(height: 256)
                }
                .listRowInsets(EdgeInsets())
            } header: {
                Text("Community's Location")
            }
        }
    }
    
    
    // MARK: - Leave Button
    
    @ViewBuilder
    private func LeaveButton() -> some View {
        Section {
            Button(role: .destructive) {
                Task {
                    try await handleCommunityExit()
                }
            } label: {
                if communityDetailVM.isLeavingCommunity {
                    HStack {
                        ProgressView()
                        Text("Leaving Community...")
                            .foregroundStyle(.gray)
                        Spacer()
                    }
                } else {
                    Label("Leave Community", systemImage: "rectangle.portrait.and.arrow.right")
                        .foregroundStyle(community.isOwner ? .gray : .red)
                }
            }
            .disabled(community.isOwner || communityDetailVM.isLeavingCommunity)
        } footer: {
            if community.isOwner {
                Text("You are the admin of this community and cannot leave it.")
            }
        }
    }
    
    // MARK: - Delete Button
    
    @ViewBuilder
    private func DeleteButton() -> some View {
        Section {
            Button(role: .destructive) {
                Task {
                    try await handleCommunityDeletion()
                }
            } label: {
                if communityDetailVM.isDeletingCommunity {
                    HStack {
                        ProgressView()
                        Text("Deleting Community...")
                            .foregroundStyle(.gray)
                        Spacer()
                    }
                } else {
                    Label("Delete Community", systemImage: "trash")
                        .foregroundStyle(.red)
                }
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
        await communityDetailVM.getCommunityInfo(communityId: community.id, token: token)
    }
    
    private func approveUser(_ user: MongoUser) async throws {
        let token = try await authVM.getFirebaseToken()
        await communityDetailVM.approveUserToCommunity(communityId: self.community.id, requestUser: user, token: token)
    }
    
    private func removeMember(at offsets: IndexSet) {
        guard community.isOwner else { return }
        
        for index in offsets {
            let member = communityDetailVM.members[index]
            
            Task {
                try await deleteMember(member)
            }
        }
    }
    
    private func deleteMember(_ user: MongoUser) async throws {
        let token = try await authVM.getFirebaseToken()
        await communityDetailVM.removeMember(communityId: self.community.id, userUidToRemove: user.userUid, token: token)
    }
    
    private func handleCommunityExit() async throws {
        do {
            try await performCommunityExit()
        } catch {
            print("❌ Error leaving community: \(error.localizedDescription)")
        }
    }
    
    private func performCommunityExit() async throws {
        let token = try await authVM.getFirebaseToken()
        try await communityDetailVM.leaveCommunity(communityId: self.community.id, token: token)
        dismiss()
        dismissCommunityMessageScreenAndRefreshCommunities()
    }
    
    private func dismissCommunityMessageScreenAndRefreshCommunities() {
        NotificationCenter.default.post(name: .popCommunity, object: nil)
    }
    
    private func handleCommunityDeletion() async throws {
        do {
            try await performCommunityDeletion()
        } catch {
            print("❌ Error deleting community: \(error.localizedDescription)")
        }
    }
    
    private func performCommunityDeletion() async throws {
        let token = try await authVM.getFirebaseToken()
        try await communityDetailVM.deleteCommunity(communityId: self.community.id, token: token)
        dismiss()
        dismissCommunityMessageScreenAndRefreshCommunities()
    }
    
    private func updateCommunityDescription(_ newDescription: String) {
        self.community.description = newDescription.isEmpty ? nil : newDescription
    }
    
    private func updateCommunityInfo() {
        self.community.name = communityDetailVM.communityNameInput
        if didChangeImage() {
            self.community.imageUrl = communityDetailVM.newImageUrl
        }
    }
    
    private func didChangeImage() -> Bool {
        let removedImage = communityDetailVM.communityImageDisplaySource == .none
        let selectedNewImage = communityDetailVM.communityImageDisplaySource == .uiImage
        return removedImage || selectedNewImage
    }
}

#Preview {
    CommunityDetailScreen(community: FormattedCommunity(id: "1", name: "Jogadores de Catan", imageUrl: nil, description: "Comunidade exclusiva para jogadores de Catan dispostos a construir aldeias e cidades diariamente.", createdAt: 0, expirationDate: 0, isMember: true, isOwner: true, isPrivate: false, isLocationVisible: false, latitude: nil, longitude: nil))
        .environmentObject(AuthenticationViewModel())
}
