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
                    locationManager: locationManager,
                    isViewDisplayed: $communityVM.isCreateCommunityViewDisplayed
                )
                .interactiveDismissDisabled(true)
            }
            .onAppear {
                Task {
                    try await getCommunities()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        communityVM.isCreateCommunityViewDisplayed = true
                    } label: {
                        Image(systemName: "person.2.badge.plus")
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
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 32) {
                ForEach(communityVM.communities) { community in
                    CommunityView(
                        imageUrl: community.imageUrl,
                        imageSize: 100,
                        name: community.name,
                        isMember: community.isMember,
                        isPrivate: community.isPrivate
                    )
                }
            }
            .padding()
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
}

#Preview {
    CommunityListScreen(locationManager: LocationManager())
        .environmentObject(AuthenticationViewModel())
}
