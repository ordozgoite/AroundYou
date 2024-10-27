//
//  DiscoveryViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 25/10/24.
//

import Foundation
import SwiftUI

@MainActor
class DiscoverViewModel: ObservableObject {
    
    @Published var isLoading: Bool = false
    @Published var isDiscoverable: Bool = false
    @Published var overlayError: (Bool, LocalizedStringKey) = (false, "")
    
    // Preferences
    @Published var displayName: String = ""
    @Published var selectedGender: Gender = .male
    @Published var selectedInterestGender: InterestGender = .everyone
    @Published var selectedAge: Int = 18
    @Published var minAge: Int = 18
    @Published var maxAge: Int = 40
    
    func verifyUserDiscoverability(token: String) async {
        isLoading = true
        let result = await AYServices.shared.verifyUserDiscoverability(token: token)
        isLoading = false
        
        switch result {
        case .success(let response):
            self.isDiscoverable = response.isUserDiscoverable
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
    }
}
