//
//  JoinCommunityView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 16/02/25.
//

import SwiftUI

struct JoinCommunityView: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @ObservedObject var communityVM: CommunityViewModel
    @ObservedObject var locationManager: LocationManager
    var community: FormattedCommunity
    
    var body: some View {
        VStack(spacing: 32) {
            CloseButton()
            
            VStack {
                CommunityImage()
                
                CommunityName()
            }
            
            CommunityDescription()
            
            JoinButton()
        }
        .padding(20)
        .frame(maxWidth: 320)
        .background(.thinMaterial)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Close Button
    
    @ViewBuilder
    private func CloseButton() -> some View {
        HStack {
            Spacer()
            
            Button {
                communityVM.isJoinCommunityViewDisplayed = false
            } label: {
                Image(systemName: "xmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20, alignment: .center)
            }
        }
    }
    
    // MARK: - Image
    
    @ViewBuilder
    private func CommunityImage() -> some View {
        ZStack(alignment: .center) {
            CircleTimerView(postDate: community.createdAt.timeIntervalSince1970InSeconds, expirationDate: community.expirationDate.timeIntervalSince1970InSeconds, size: 136)
            
            CommunityImageView(imageUrl: community.imageUrl, size: 128)
                .shadow(radius: 5)
        }
    }
    
    // MARK: - Name
    
    @ViewBuilder
    private func CommunityName() -> some View {
        Text(community.name)
            .font(.title)
            .bold()
    }
    
    // MARK: - Description
    
    @ViewBuilder
    private func CommunityDescription() -> some View {
        if let description = community.description {
            Text(description)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Join Button
    
    @ViewBuilder
    private func JoinButton() -> some View {
        if communityVM.isJoiningCommunity {
            AYProgressButton(title: community.isPrivate ? "Asking..." : "Joining...")
        } else {
            AYButton(title: community.isPrivate ? "Ask To Join" : "Join") {
                if community.isPrivate {
                    Task {
                        try await askToJoinCommunity()
                    }
                } else {
                    Task {
                        try await joinCommunity()
                    }
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func joinCommunity() async throws {
        locationManager.requestLocation()
        if let location = locationManager.location {
            let token = try await authVM.getFirebaseToken()
            
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            
            await communityVM.joinCommunity(withId: community.id, latitude: latitude, longitude: longitude, token: token)
        }
    }
    
    private func askToJoinCommunity() async throws {
        locationManager.requestLocation()
        if let location = locationManager.location {
            let token = try await authVM.getFirebaseToken()
            
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            
            await communityVM.askToJoinCommunity(withId: community.id, latitude: latitude, longitude: longitude, token: token)
        }
    }
}

#Preview {
    JoinCommunityView(
        communityVM: CommunityViewModel(),
        locationManager: LocationManager(),
        community: FormattedCommunity(id: UUID().uuidString, name: "Condomínio Anaíra", imageUrl: nil, description: "Comunidade apenas para moradores do Anaíra", createdAt: 1, expirationDate: 1, isMember: false, isOwner: false, isPrivate: true, isLocationVisible: false, latitude: nil, longitude: nil)
    )
}
