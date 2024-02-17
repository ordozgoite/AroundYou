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
    
    func getUserProfile(userUid: String, token: String) async {
        isLoading = true
        let response = await AYServices.shared.getUserProfile(userUid: userUid, token: token)
        isLoading = false
        
        switch response {
        case .success(let user):
            userProfile = user
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
    }
    
}
