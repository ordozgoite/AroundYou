//
//  UserProfileViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 16/02/24.
//

import Foundation
import SwiftUI

@MainActor
class UserProfileViewModel: ObservableObject {
    
    @Published var userProfile: UserProfile? = nil
    @Published var isLoading: Bool = false
    @Published var isPostingChat: Bool = false
    @Published var overlayError: (Bool, LocalizedStringKey) = (false, "")
    @Published var isReportScreenPresented: Bool = false
    @Published var isBlockAlertPresented: Bool = false
    @Published var isProfilePicFullScreen: Bool = false
    @Published var image: UIImage?
    
    func getUserProfile(userUid: String, token: String) async {
        isLoading = true
        let result = await AYServices.shared.getUserProfile(userUid: userUid, token: token)
        isLoading = false
        
        switch result {
        case .success(let user):
            userProfile = user
        case .failure:
            overlayError = (true, ErrorMessage.getUserProfile)
        }
    }
    
    func blockUser(blockedUserUid: String, token: String, dismissScreen: () -> ()) async {
        isLoading = true
        let result = await AYServices.shared.blockUser(blockedUserUid: blockedUserUid, token: token)
        isLoading = false
        
        switch result {
        case .success:
            dismissScreen()
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
    }
    
    func postNewChat(otherUserUid: String, token: String) async throws -> Chat {
        isPostingChat = true
        let result = await AYServices.shared.postNewChat(otherUserUid: otherUserUid, token: token)
        isPostingChat = false
        
        switch result {
        case .success(let chat):
            return chat
        case .failure(let error):
            overlayError = (true, ErrorMessage.postNewChat)
            throw error
        }
    }
}
