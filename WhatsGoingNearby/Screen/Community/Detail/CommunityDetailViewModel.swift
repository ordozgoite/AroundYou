//
//  CommunityDetailViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 19/02/25.
//

import Foundation
import SwiftUI

@MainActor
class CommunityDetailViewModel: ObservableObject {
    
    @Published var members: [MongoUser] = []
    @Published var joinRequests: [MongoUser]?
    @Published var communityOwnerUid: String = ""
    @Published var overlayError: (Bool, LocalizedStringKey) = (false, "")
    @Published var hasFetchedCommunityInfo: Bool = false
    @Published var isEditDescriptionViewDisplayed: Bool = false
    
    // Loading
    @Published var isApprovingUserToCommunity: (Bool, String) = (false, "")
    @Published var isLeavingCommunity: Bool = false
    @Published var isDeletingCommunity: Bool = false
    @Published var isEditingDescription: Bool = false
    
    func getCommunityInfo(communityId: String, token: String) async {
        let result = await AYServices.shared.getCommunityInfo(communityId: communityId, token: token)
        
        switch result {
        case .success(let communityInfo):
            setCommunityInfo(communityInfo)
            hasFetchedCommunityInfo = true
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
    }
    
    private func setCommunityInfo(_ communityInfo: GetCommunityInfoResponse) {
        self.members = communityInfo.members
        self.joinRequests = communityInfo.joinRequests
        self.communityOwnerUid = communityInfo.ownerUid
    }
    
    func approveUserToCommunity(communityId: String, requestUser: MongoUser, token: String) async {
        isApprovingUserToCommunity = (true, requestUser.userUid)
        let response = await AYServices.shared.approveUserToCommunity(communityId: communityId, requestUserUid: requestUser.userUid, token: token)
        isApprovingUserToCommunity = (false, "")
        
        switch response {
        case .success:
            removeFromJoinRequests(requestUser.userUid)
            addToMembers(requestUser)
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
    }
    
    private func removeFromJoinRequests(_ userUid: String) {
        guard var requests = joinRequests else { return }
        requests.removeAll { $0.userUid == userUid }
        joinRequests = requests
    }

    
    private func addToMembers(_ user: MongoUser) {
        self.members.append(user)
    }
    
    func removeMember(communityId: String, userUidToRemove: String, token: String) async {
        let response = await AYServices.shared.removeUserFromCommunity(communityId: communityId, userUidToRemove: userUidToRemove, token: token)
        
        switch response {
        case .success:
            removeFromMembers(userUidToRemove)
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
    }
    
    private func removeFromMembers(_ userUid: String) {
        members.removeAll { $0.userUid == userUid }
    }
    
    func leaveCommunity(communityId: String, token: String) async throws {
        isLeavingCommunity = true
        let response = await AYServices.shared.exitCommunity(communityId: communityId, token: token)
        isLeavingCommunity = false
        
        switch response {
        case .success:
            print("✅ Success!")
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
            throw NSError(domain: "LeaveCommunityError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to leave community"])
        }
    }
    
    func deleteCommunity(communityId: String, token: String) async throws {
        isDeletingCommunity = true
        let response = await AYServices.shared.deleteCommunity(communityId: communityId, token: token)
        isDeletingCommunity = false
        
        switch response {
        case .success:
            print("✅ Success!")
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
            throw NSError(domain: "DeleteCommunityError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to delete community"])
        }
    }
    
    func editCommunityDescription(communityId: String, newDescription: String?, token: String) async throws {
        isEditingDescription = true
        let response = await AYServices.shared.editCommunityDescription(communityId: communityId, description: newDescription, token: token)
        isEditingDescription = false
        
        switch response {
        case .success:
            print("✅ Success!")
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
            throw NSError(domain: "EditCommunityDescriptionError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to edit community description"])
        }
    }
}
