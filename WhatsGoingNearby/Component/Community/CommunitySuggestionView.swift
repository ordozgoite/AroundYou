//
//  CommunitySuggestionView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 04/02/25.
//

import SwiftUI

struct CommunitySuggestionView: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @ObservedObject var communityVM: CommunityViewModel
    
    var body: some View {
        VStack {
            Header()
            
            Communities()
        }
        .background(
            RoundedRectangle(cornerRadius: 16).fill(.thinMaterial)
        )
    }
    
    // MARK: - Header
    
    @ViewBuilder
    private func Header() -> some View {
        HStack {
            Label("Communities", systemImage: "figure.2")
                .foregroundStyle(.gray)
            
            Spacer()
            
            NavigationLink(destination: CommunityScreen().environmentObject(authVM)) {
                Text("View All")
                    .foregroundStyle(.gray)
                    .fontWeight(.bold)
            }
        }
        .padding([.top, .trailing, .leading])
    }
    
    // MARK: - Communities
    
    @ViewBuilder
    private func Communities() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(communityVM.communities) { community in
                    CommunityImageView(imageUrl: community.imageUrl, size: 64)
                }
                
                NewCommunity()
            }
        }
        .padding(.bottom, 16)
    }
    
    // MARK: - New Community
    
    @ViewBuilder
    private func NewCommunity() -> some View {
        Image(systemName: "plus.circle.fill")
            .resizable()
            .scaledToFit()
            .frame(height: 64)
            .foregroundStyle(.gray.opacity(0.25))
    }
}

#Preview {
    CommunitySuggestionView(communityVM: CommunityViewModel())
        .environmentObject(AuthenticationViewModel())
}
