//
//  CommunitySuggestionView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 04/02/25.
//

import SwiftUI

struct CommunitySuggestionView: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var communityVM = CommunityViewModel() // another instance??
    @ObservedObject var locationManager: LocationManager
    
    var body: some View {
        VStack {
            Header()
            
            Communities()
        }
        .background(
            RoundedRectangle(cornerRadius: 16).fill(.thinMaterial)
        )
//        .sheet(isPresented: $communityVM.isCreateCommunityViewDisplayed) {
//            CreateCommunityScreen(
//                locationManager: locationManager, communityVM: <#CommunityViewModel#>,
//                isViewDisplayed: $communityVM.isCreateCommunityViewDisplayed
//            )
//            .interactiveDismissDisabled(true)
//        }
    }
    
    // MARK: - Header
    
    @ViewBuilder
    private func Header() -> some View {
        HStack {
            Label("Communities Around You", systemImage: "figure.2")
                .foregroundStyle(.gray)
            
            Spacer()
            
//            NavigationLink(destination: CommunityListScreen(communityVM: communityVM).environmentObject(authVM)) {
                Text("View All")
                    .foregroundStyle(.gray)
                    .fontWeight(.bold)
//            }
        }
        .padding([.top, .trailing, .leading])
    }
    
    // MARK: - Communities
    
    @ViewBuilder
    private func Communities() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(communityVM.communities) { community in
                    CommunityImageView(imageUrl: community.imageUrl, size: 50)
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
            .frame(height: 32 )
            .foregroundStyle(.gray.opacity(0.25))
            .onTapGesture {
                communityVM.isCreateCommunityViewDisplayed = true
            }
    }
}

#Preview {
    CommunitySuggestionView(locationManager: LocationManager())
        .environmentObject(AuthenticationViewModel())
}
