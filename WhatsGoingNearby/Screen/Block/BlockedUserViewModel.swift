//
//  BlockedUserViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 18/02/24.
//

import Foundation
import SwiftUI

@MainActor
class BlockedUserViewModel: ObservableObject {
    
    @Published var blockedUsers: [UserProfile] = []
    @Published var isLoading: Bool = false
    @Published var isUnblockAlertDisplayed: Bool = false
    @Published var selectedUser: UserProfile?
    @Published var overlayError: (Bool, LocalizedStringKey) = (false, "")
    
    func getBockeUser(token: String) async {
        isLoading = true
        let result = await AYServices.shared.getBlockedUsers(token: token)
        isLoading = false
        
        switch result {
        case .success(let users):
            blockedUsers = users
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
    }
    
    func unblockUser(blockedUserUid:String, token: String) async {
        isLoading = true
        let result = await AYServices.shared.unblockUser(blockedUserUid: blockedUserUid, token: token)
        isLoading = false
        
        switch result {
        case .success:
            removeBlockedUser(withUserUid: blockedUserUid)
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
    }
    
    private func removeBlockedUser(withUserUid userUidToRemove: String) {
        blockedUsers.removeAll { $0.userUid == userUidToRemove }
    }
}
