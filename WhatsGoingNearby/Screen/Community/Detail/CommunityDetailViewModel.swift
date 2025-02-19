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
    
    func leaveCommunity() async {
        
    }
    
    func deleteCommunity() async {
        
    }
}
