//
//  CommunityScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 03/02/25.
//

import SwiftUI

struct CommunityListScreen: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var communityVM = CommunityViewModel()
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
            }
            .sheet(isPresented: $communityVM.isCreateCommunityViewDisplayed) {
                CreateCommunityScreen(
                    communityVM: communityVM,
                    locationManager: locationManager,
                    isViewDisplayed: $communityVM.isCreateCommunityViewDisplayed
                )
                .interactiveDismissDisabled(true)
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
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        communityVM.isCreateCommunityViewDisplayed = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .navigationTitle("Communities")
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
                            .onTapGesture {
                                if community.isMember {
                                    communityVM.selectedCommunityToChat = community
                                    communityVM.isCommunityChatScreenDisplayed = true
                                } else {
                                    communityVM.selectedCommunityToJoin = community
                                    communityVM.isJoinCommunityViewDisplayed = true
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            
            JoinCommunity()
        }
        .navigationDestination(isPresented: $communityVM.isCommunityChatScreenDisplayed) {
            if let community = communityVM.selectedCommunityToChat {
                CommunityMessageScreen(
                    community: community,
                    socket: socket
                )
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
    
    // MARK: - Private Methods
    
    private func getCommunities() async throws {
        locationManager.requestLocation()
        if let location = locationManager.location {
            let token = try await authVM.getFirebaseToken()
            
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            
            await communityVM.getCommunitiesNearBy(latitude: latitude, longitude: longitude, token: token)
        }
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
    CommunityListScreen(locationManager: LocationManager(), socket: SocketService())
        .environmentObject(AuthenticationViewModel())
}
