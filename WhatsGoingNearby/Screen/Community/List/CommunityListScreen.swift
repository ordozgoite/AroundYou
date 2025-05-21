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
            .alert(item: $communityVM.activeAlert) { alert in
                switch alert {
                case .delete(let community):
                    return Alert(
                        title: Text("Delete Community"),
                        message: Text("Do you really want to delete the community **\(community.name)**?"),
                        primaryButton: .destructive(Text("Delete")) {
                            Task {
                                let token = try await authVM.getFirebaseToken()
                                try await communityVM.deleteCommunity(communityId: community.id, token: token)
                            }
                        },
                        secondaryButton: .cancel()
                    )
                    
                case .leave(let community):
                    return Alert(
                        title: Text("Leave Community"),
                        message: Text("Do you really want to leave the community **\(community.name)**?"),
                        primaryButton: .destructive(Text("Leave")) {
                            Task {
                                let token = try await authVM.getFirebaseToken()
                                await communityVM.leaveCommunity(communityId: community.id, token: token)
                            }
                        },
                        secondaryButton: .cancel()
                    )
                    
                case .farAway(let community):
                    return Alert(
                        title: Text(community.name),
                        message: Text("You are too far from this community. Tap and hold to leave it."),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
//            .alert(item: $communityVM.selectedCommunityToDelete) { community in
//                Alert(
//                    title: Text("Delete Community"),
//                    message: Text("Do you really want to delete the community **\(community.name)**?"),
//                    primaryButton: .destructive(Text("Delete")) {
//                        Task {
//                            let token = try await authVM.getFirebaseToken()
//                            try await communityVM.deleteCommunity(communityId: community.id, token: token)
//                        }
//                    },
//                    secondaryButton: .cancel()
//                )
//            }
//            .alert(item: $communityVM.selectedCommunityToLeave) { community in
//                Alert(
//                    title: Text("Leave Community"),
//                    message: Text("Do you really want to leave the community **\(community.name)**?"),
//                    primaryButton: .destructive(Text("Leave")) {
//                        Task {
//                            let token = try await authVM.getFirebaseToken()
//                            await communityVM.leaveCommunity(communityId: community.id, token: token)
//                        }
//                    },
//                    secondaryButton: .cancel()
//                )
//            }
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
            .contextMenu {
                CommunityMenu(community)
            }
            
            .onTapGesture {
                tapOnCommunity(community)
            }
        }
    }
    
    // MARK: - Menu
    
    @ViewBuilder
    private func CommunityMenu(_ community: FormattedCommunity) -> some View {
        if community.isOwner {
            Button {
                communityVM.activeAlert = .delete(community)
            } label: {
                Label("Delete Community", systemImage: "trash")
            }
        } else if community.isMember {
            Button {
                communityVM.activeAlert = .leave(community)
            } label: {
                Label("Leave Community", systemImage: "rectangle.portrait.and.arrow.right")
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
    
    // MARK: - Create Community
    
    @ViewBuilder
    private func CreateCommunityButton() -> some View {
        Button {
            communityVM.isCreateCommunityScreenDisplayed = true
        } label: {
            Image(systemName: "plus")
        }
//        .alert(item: $communityVM.selectedFarAwayCommunity) { community in
//            Alert(title: Text(community.name), message: Text("You are too far from this community. Tap and hold to leave it."), dismissButton: nil)
//        }
    }
    
    // MARK: - Private Methods
    
    private func getCommunities() async throws {
        locationManager.requestLocation()
        if let location = locationManager.location {
            let token = try await authVM.getFirebaseToken()
            
            let currentLocation = Location(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            
            await communityVM.getCommunities(location: currentLocation, token: token)
        }
    }
    
    private func tapOnCommunity(_ community: FormattedCommunity) {
        if isOwner(forCommunity: community) || isNearByMember(forCommunity: community) {
            goToCommunity(community)
        } else if isFarAwayMember(forCommunity: community) {
            displayFarAwayAlert(forCommunity: community)
        } else {
            displayJoinCommunityView(community)
        }
    }
    
    private func isOwner(forCommunity community: FormattedCommunity) -> Bool {
        return community.isOwner
    }
    
    private func isNearByMember(forCommunity community: FormattedCommunity) -> Bool {
        return !community.isOwner && community.isMember && community.isNearBy
    }
    
    private func isFarAwayMember(forCommunity community: FormattedCommunity) -> Bool {
        return !community.isOwner && community.isMember && !community.isNearBy
    }
    
    private func goToCommunity(_ community: FormattedCommunity) {
        communityVM.selectedCommunityToChat = community
        communityVM.isCommunityChatScreenDisplayed = true
    }
    
    private func displayFarAwayAlert(forCommunity community: FormattedCommunity) {
        print("⚠️ Should display popover!")
//        communityVM.selectedFarAwayCommunity = community
        communityVM.activeAlert = .farAway(community)
    }
    
    private func displayJoinCommunityView(_ community: FormattedCommunity) {
        communityVM.selectedCommunityToJoin = community
        communityVM.isJoinCommunityViewDisplayed = true
    }
    
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
