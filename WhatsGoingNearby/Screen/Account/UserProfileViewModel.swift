//
//  UserProfileViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 16/02/24.
//

import Foundation

@MainActor
class UserProfileViewModel: ObservableObject {
    
    @Published var userProfile: UserProfile? = nil
    @Published var isLoading: Bool = false
    @Published var overlayError: (Bool, String) = (false, "")
    @Published var isReportScreenPresented: Bool = false
    @Published var isBlockAlertPresented: Bool = false
    
    func getUserProfile(userUid: String, token: String) async {
        isLoading = true
        let result = await AYServices.shared.getUserProfile(userUid: userUid, token: token)
        isLoading = false
        
        switch result {
        case .success(let user):
            userProfile = user
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
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
}
