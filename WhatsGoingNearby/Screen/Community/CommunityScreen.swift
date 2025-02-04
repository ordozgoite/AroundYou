//
//  CommunityScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 03/02/25.
//

import SwiftUI

struct CommunityScreen: View {
    
    @StateObject private var communityVM = CommunityViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                if communityVM.isLoading {
                    LoadingView()
                } else if communityVM.communities.isEmpty {
                    // EmptyCommunityView()
                } else {
                    Communities()
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
}

#Preview {
    CommunityScreen()
}
