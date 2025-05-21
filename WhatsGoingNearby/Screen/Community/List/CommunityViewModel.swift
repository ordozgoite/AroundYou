//
//  CommunityViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 04/02/25.
//

import Foundation
import SwiftUI

enum CommunityAlertType: Identifiable {
    case delete(FormattedCommunity)
    case leave(FormattedCommunity)
    case farAway(FormattedCommunity)
    
    var id: String {
        switch self {
        case .delete(let community), .leave(let community), .farAway(let community):
            return community.id
        }
    }
}


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
    @Published var activeAlert: CommunityAlertType?

//    @Published var selectedCommunityToDelete: FormattedCommunity? = nil
//    @Published var selectedFarAwayCommunity: FormattedCommunity? = nil
//    @Published var selectedCommunityToLeave: FormattedCommunity? = nil
    
    // Join Community
    @Published var isJoinCommunityViewDisplayed: Bool = false
    @Published var selectedCommunityToJoin: FormattedCommunity?
    @Published var isJoiningCommunity: Bool = false
    
    //    func getCommunitiesNearBy(latitude: Double, longitude: Double, token: String) async {
    //        if !initialCommunitiesFetched { isLoading = true }
    //        let result = await AYServices.shared.getCommunitiesNearBy(latitude: latitude, longitude: longitude, token: token)
    //        if !initialCommunitiesFetched { isLoading = false }
    //
    //        switch result {
    //        case .success(let communities):
    //            self.communitiesNearBy = communities
    //            initialCommunitiesFetched = true
    //        case .failure:
    //            overlayError = (true, ErrorMessage.getCommunitiesNearBy)
    //        }
    //    }
    
    func getCommunities(location: Location, token: String) async {
        if !initialCommunitiesFetched { isLoading = true }
        let result = await AYServices.shared.getRelevantCommunities(location: location, token: token)
        if !initialCommunitiesFetched { isLoading = false }
        
        switch result {
        case .success(let communities):
            self.communities = communities
            initialCommunitiesFetched = true
        case .failure:
            overlayError = (true, ErrorMessage.getCommunitiesNearBy)
        }
    }
    
    func joinCommunity(withId communityId: String, latitude: Double, longitude: Double, token: String) async {
        isJoiningCommunity = true
        let result = await AYServices.shared.joinCommunity(communityId: communityId, latitude: latitude, longitude: longitude, token: token)
        isJoiningCommunity = false
        
        switch result {
        case .success:
            isJoinCommunityViewDisplayed = false
            updateListAfterJoiningCommunity(withId: communityId)
            goToChat(forCommunityId: communityId)
        case .failure:
            overlayError = (true, ErrorMessage.joinCommunity)
        }
    }
    
    private func updateListAfterJoiningCommunity(withId communityId: String) {
        if let index = communities.firstIndex(where: { $0.id == communityId }) {
            communities[index].isMember = true
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
            updateListAfterAskingToJoinCommunity(withId: communityId)
        case .failure(let error):
            if error == .conflict {
                overlayError = (true, ErrorMessage.askToJoinCommunityRepeatedAction)
            } else {
                overlayError = (true, ErrorMessage.askToJoinCommunity)
            }
        }
    }
    
    private func updateListAfterAskingToJoinCommunity(withId communityId: String) {
        if let index = communities.firstIndex(where: { $0.id == communityId }) {
            communities[index].askedToJoin = true
        }
    }
    
    func deleteCommunity(communityId: String, token: String) async throws {
        let result = await AYServices.shared.deleteCommunity(communityId: communityId, token: token)
        
        switch result {
        case .success:
            removeCommunity(withId: communityId)
        case .failure:
            overlayError = (true, ErrorMessage.deleteCommunity)
            throw NSError(domain: "DeleteCommunityError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to delete community"])
        }
    }
    
    private func removeCommunity(withId communityId: String) {
        self.communities.removeAll { $0.id == communityId }
    }
    
    func leaveCommunity(communityId: String, token: String) async {
        let result = await AYServices.shared.exitCommunity(communityId: communityId, token: token)
        
        switch result {
        case .success:
            updateListAfterLeavingCommunity(withId: communityId)
        case .failure:
            overlayError = (true, ErrorMessage.leaveCommunity)
        }
    }
    
    private func updateListAfterLeavingCommunity(withId communityId: String) {
        if let index = communities.firstIndex(where: { $0.id == communityId }) {
            if communities[index].isNearBy {
                communities[index].isMember = false
            } else {
                removeCommunity(withId: communityId)
            }
        }
    }
}
