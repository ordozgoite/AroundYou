//
//  CommunityScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 03/02/25.
//

import SwiftUI

struct CommunityListScreen: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @ObservedObject var communityVM: CommunityViewModel
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var socket: SocketService
    
    @State private var timer: Timer?
    
    var body: some View {
        NavigationStack {
            ZStack {
                if communityVM.isLoading {
                    LoadingView()
                } else if communityVM.communities.isEmpty {
                    EmptyCommunityView()
                } else {
                    Communities()
                }
                
                AYErrorAlert(message: communityVM.overlayError.1 , isErrorAlertPresented: $communityVM.overlayError.0)
            }
            .navigationDestination(isPresented: $communityVM.isCreateCommunityScreenDisplayed) {
                CreateCommunityScreen(
                    communityVM: communityVM,
                    locationManager: locationManager
                )
                .environmentObject(authVM)
            }
            .onAppear {
                Task {
                    try await getCommunities()
                }
                startExpirationTimer()
            }
            .onDisappear {
                stopExpirationTimer()
            }
            .toolbar {
                CreateCommunityButton()
            }
        }
    }
    
    //MARK: - Loading
    
    @ViewBuilder
    private func LoadingView() -> some View {
        VStack {
            AYProgressView()
            
            Text("Looking around you...")
                .foregroundStyle(.gray)
                .fontWeight(.semibold)
        }
        .frame(maxHeight: .infinity, alignment: .center)
    }
    
    // MARK: - Communities
    
    @ViewBuilder
    private func Communities() -> some View {
        ZStack {
            ScrollView {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), alignment: .top),
                        GridItem(.flexible(), alignment: .top),
                        GridItem(.flexible(), alignment: .top)
                    ],
                    spacing: 32
                ) {
                    ForEach(communityVM.communities) { community in
                        Community(community)
                    }
                }
                .padding()
            }
            .refreshable {
                hapticFeedback(style: .soft)
                communityVM.initialCommunitiesFetched = false
                Task {
                    try await getCommunities()
                }
            }
            
            JoinCommunity()
        }
        .alert(item: $communityVM.selectedCommunityToDelete) { community in
            Alert(
                title: Text("Delete Community"),
                message: Text("Do you really want to delete the community \(community.name)?"),
                primaryButton: .destructive(Text("Delete")) {
                    Task {
                        let token = try await authVM.getFirebaseToken()
                        try await communityVM.deleteCommunity(communityId: community.id, token: token)
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .navigationDestination(isPresented: $communityVM.isCommunityChatScreenDisplayed) {
            if let community = communityVM.selectedCommunityToChat {
                CommunityMessageScreen(
                    community: community,
                    isViewDisplayed: $communityVM.isCommunityChatScreenDisplayed,
                    locationManager: locationManager,
                    socket: socket
                ) {
                    Task {
                        try await getCommunities()
                    }
                }
                .environmentObject(authVM)
            }
        }
    }
    
    // MARK: - Community
    
    @ViewBuilder
    private func Community(_ community: FormattedCommunity) -> some View {
        if community.isActive {
            ZStack(alignment: .topTrailing) {
                CommunityView(
                    imageUrl: community.imageUrl,
                    imageSize: 64,
                    name: community.name,
                    isMember: community.isMember,
                    isPrivate: community.isPrivate,
                    creationDate: community.createdAt.timeIntervalSince1970InSeconds,
                    expirationDate: community.expirationDate.timeIntervalSince1970InSeconds
                )
                .opacity(community.isNearBy ? 1 : 0.5)
                .onTapGesture {
                    if community.isNearBy {
                        if community.isMember {
                            communityVM.selectedCommunityToChat = community
                            communityVM.isCommunityChatScreenDisplayed = true
                        } else {
                            communityVM.selectedCommunityToJoin = community
                            communityVM.isJoinCommunityViewDisplayed = true
                        }
                    }
                }
                
                if community.isOwner {
                    RemoveMediaButton(size: .small)
                        .onTapGesture {
                            communityVM.selectedCommunityToDelete = community
                        }
                }
            }
        }
    }
    
    // MARK: - Join Community
    
    @ViewBuilder
    private func JoinCommunity() -> some View {
        if communityVM.isJoinCommunityViewDisplayed, let community = communityVM.selectedCommunityToJoin {
            JoinCommunityView(
                communityVM: communityVM,
                locationManager: locationManager,
                community: community
            )
        }
    }
    
    // MARK: - Ellipsis
    
    //    @ViewBuilder
    //    private func Ellipsis() -> some View {
    //        Menu {
    //            CreateCommunityButton()
    //
    //            Divider()
    //
    //            MyCommunities()
    //        } label: {
    //            Image(systemName: "ellipsis.circle")
    //        }
    //        .sheet(isPresented: $communityVM.isMyCommunitiesViewDisplayed) {
    //            MyCommunitiesView(communityVM: communityVM)
    //                .environmentObject(authVM)
    //        }
    //    }
    
    // MARK: - Create Community
    
    @ViewBuilder
    private func CreateCommunityButton() -> some View {
        Button {
            communityVM.isCreateCommunityScreenDisplayed = true
        } label: {
            Image(systemName: "plus")
        }
    }
    
    // MARK: - My Communities
    
    //    @ViewBuilder
    //    private func MyCommunities() -> some View {
    //        Button {
    //            communityVM.isMyCommunitiesViewDisplayed = true
    //        } label: {
    //            Label("My Communities", systemImage: "list.bullet")
    //        }
    //
    //    }
    
    // MARK: - Private Methods
    
    private func getCommunities() async throws {
        locationManager.requestLocation()
        if let location = locationManager.location {
            let token = try await authVM.getFirebaseToken()
            
            let currentLocation = Location(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            
            await communityVM.getCommunities(location: currentLocation, token: token)
        }
    }
    
    //    private func getMyCommunties() async throws {
    //        let token = try await authVM.getFirebaseToken()
    //        await communityVM.getCommunitiesFromUser(token: token)
    //    }
    
    private func startExpirationTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.removeExpiredCommunities()
        }
    }
    
    private func stopExpirationTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func removeExpiredCommunities() {
        DispatchQueue.main.async {
            communityVM.communities.removeAll { !$0.isActive }
        }
    }
}

#Preview {
    CommunityListScreen(communityVM: CommunityViewModel(), locationManager: LocationManager(), socket: SocketService())
        .environmentObject(AuthenticationViewModel())
}
