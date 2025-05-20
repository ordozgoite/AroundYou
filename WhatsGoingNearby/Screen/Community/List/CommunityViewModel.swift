//
//  CommunityViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 04/02/25.
//

import Foundation
import SwiftUI

@MainActor
class CommunityViewModel: ObservableObject {
    
    @Published var communities: [FormattedCommunity] = []
    @Published var isLoading: Bool = false
    @Published var isCreateCommunityScreenDisplayed: Bool = false
    @Published var isMyCommunitiesViewDisplayed: Bool = false
    @Published var initialCommunitiesFetched: Bool = false
    @Published var overlayError: (Bool, LocalizedStringKey) = (false, "")
    @Published var isCommunityChatScreenDisplayed: Bool = false
    @Published var selectedCommunityToChat: FormattedCommunity?
    
    // MyCommunities
    @Published var userCommunities: [FormattedCommunity]? = nil
    @Published var isFetchingUserCommunities: Bool = false
    
    // Join Community
    @Published var isJoinCommunityViewDisplayed: Bool = false
    @Published var selectedCommunityToJoin: FormattedCommunity?
    @Published var isJoiningCommunity: Bool = false
    
    func getCommunitiesNearBy(latitude: Double, longitude: Double, token: String) async {
        if !initialCommunitiesFetched { isLoading = true }
        let result = await AYServices.shared.getCommunitiesNearBy(latitude: latitude, longitude: longitude, token: token)
        if !initialCommunitiesFetched { isLoading = false }
        
        switch result {
        case .success(let communities):
            self.communities = communities
            initialCommunitiesFetched = true
        case .failure:
            overlayError = (true, ErrorMessage.getCommunitiesNearBy)
        }
    }
    
    func getCommunitiesFromUser(token: String) async {
        isFetchingUserCommunities = true
        defer { isFetchingUserCommunities = false }
        let result = await AYServices.shared.getMyCommunities(token: token)
        
        switch result {
        case .success(let communities):
            self.userCommunities = communities
        case .failure:
            overlayError = (true, "Error trying to fetch my communities. Please try again.")
        }
    }
    
    func joinCommunity(withId communityId: String, latitude: Double, longitude: Double, token: String) async {
        isJoiningCommunity = true
        let result = await AYServices.shared.joinCommunity(communityId: communityId, latitude: latitude, longitude: longitude, token: token)
        isJoiningCommunity = false
        
        switch result {
        case .success:
            isJoinCommunityViewDisplayed = false
            goToChat(forCommunityId: communityId)
            await getCommunitiesNearBy(latitude: latitude, longitude: longitude, token: token)
        case .failure:
            overlayError = (true, ErrorMessage.joinCommunity)
        }
    }
    
    private func goToChat(forCommunityId communityId: String) {
        if let index = getCommunityIndex(forCommunityId: communityId) {
            selectedCommunityToChat = communities[index]
            isCommunityChatScreenDisplayed = true
        }
    }
    
    private func getCommunityIndex(forCommunityId communityId: String) -> Int? {
        return communities.firstIndex { $0.id == communityId }
    }
    
    func askToJoinCommunity(withId communityId: String, latitude: Double, longitude: Double, token: String) async {
        isJoiningCommunity = true
        let result = await AYServices.shared.askToJoinCommunity(communityId: communityId, latitude: latitude, longitude: longitude, token: token)
        isJoiningCommunity = false
        
        switch result {
        case .success:
            isJoinCommunityViewDisplayed = false
            await getCommunitiesNearBy(latitude: latitude, longitude: longitude, token: token)
        case .failure(let error):
            if error == .conflict {
                overlayError = (true, ErrorMessage.askToJoinCommunityRepeatedAction)
            } else {
                overlayError = (true, ErrorMessage.askToJoinCommunity)
            }
        }
    }
}
