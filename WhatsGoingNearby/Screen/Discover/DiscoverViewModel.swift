//
//  DiscoveryViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 25/10/24.
//

import Foundation
import SwiftUI

enum Gender: String, CaseIterable, Identifiable {
    case male = "male"
    case female = "female"
    
    var id: String { self.rawValue }
}

enum InterestGender: String, CaseIterable, Identifiable {
    case male = "male"
    case female = "female"
    case everyone = "everyone"
    
    var id: String { self.rawValue }
}

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
    @Published var ageRange: ClosedRange<Double> = 18...40
    
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
