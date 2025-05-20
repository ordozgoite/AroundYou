//
//  MyCommunitiesView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 20/05/25.
//

import SwiftUI

struct MyCommunitiesView: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @ObservedObject var communityVM: CommunityViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                if communityVM.isFetchingUserCommunities {
                    ProgressView()
                } else if let myCommunities = communityVM.userCommunities {
                    if myCommunities.isEmpty {
                        NoCommunityMessage()
                    } else {
                        MyCommunities(myCommunities)
                    }
                }
            }
            .navigationTitle("My Communities")
        }
    }
    
    // MARK: - No Community
    
    @ViewBuilder
    private func NoCommunityMessage() -> some View {
        Text("You don't have any active community.")
            .bold()
            .foregroundStyle(.gray)
    }
    
    // MARK: - My Communities
    
    @ViewBuilder
    private func MyCommunities(_ myCommunities: [FormattedCommunity]) -> some View {
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
                    ForEach(myCommunities) { community in
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
                                // TODO: Display DeleteCommunityView
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }
}

#Preview {
    MyCommunitiesView(communityVM: CommunityViewModel())
        .environmentObject(AuthenticationViewModel())
}
