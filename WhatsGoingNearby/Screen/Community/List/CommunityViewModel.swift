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
    @Published var isCreateCommunityViewDisplayed: Bool = false
    @Published var initialCommunitiesFetched: Bool = false
    @Published var isJoinCommunityViewDisplayed: Bool = false
    @Published var selectedCommunityToJoin: FormattedCommunity?
    
    func getCommunitiesNearBy(latitude: Double, longitude: Double, token: String) async {
        if !initialCommunitiesFetched { isLoading = true }
        let result = await AYServices.shared.getCommunitiesNearBy(latitude: latitude, longitude: longitude, token: token)
        if !initialCommunitiesFetched { isLoading = false }
        
        switch result {
        case .success(let communities):
            self.communities = communities
            initialCommunitiesFetched = true
        case .failure(let error):
            // TODO: Display Error
            print("Error: \(error)")
        }
    }
}
