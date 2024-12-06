//
//  DiscoveryViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 25/10/24.
//

import Foundation
import SwiftUI

struct UserDiscoverInfo: Codable, Identifiable {
    let id: String
    let imageUrl: String?
    let displayName: String
    let gender: Gender
    let age: Int
}

@MainActor
class DiscoverViewModel: ObservableObject {
    
    @Published var isLoading: Bool = false
    @Published var discoverabilityVerified: Bool = false
    @Published var isActivatingDiscover: Bool = false
    @Published var overlayError: (Bool, LocalizedStringKey) = (false, "")
    @Published var isPreferencesViewDisplayed: Bool = false
    
    // Preferences
    @Published var isSettingPreferences: Bool = false
    @Published var isHidingAccount: Bool = false
    @Published var selectedGender: Gender = .cisMale
    @Published var selectedInterestGenders: Set<Gender> = []
    private var interestGendersAsStrings: [String] {
        selectedInterestGenders.map { $0.description }
    }
    @Published var selectedAge: Int = 18
    @Published var ageRange: ClosedRange<Double> = 18...40
    
    // Discover
    @Published var usersFound: [UserDiscoverInfo] = [
        UserDiscoverInfo(id: "1", imageUrl: "https://br.web.img2.acsta.net/pictures/19/04/29/20/14/1886009.jpg", displayName: "Megan Fox", gender: .cisFemale, age: 38),
        UserDiscoverInfo(id: "2", imageUrl: "https://br.web.img2.acsta.net/pictures/19/04/29/20/14/1886009.jpg", displayName: "Megan Fox", gender: .cisFemale, age: 38),
        UserDiscoverInfo(id: "3", imageUrl: "https://br.web.img2.acsta.net/pictures/19/04/29/20/14/1886009.jpg", displayName: "Megan Fox", gender: .cisFemale, age: 38),
        UserDiscoverInfo(id: "4", imageUrl: "https://br.web.img2.acsta.net/pictures/19/04/29/20/14/1886009.jpg", displayName: "Megan Fox", gender: .cisFemale, age: 38),
        UserDiscoverInfo(id: "5", imageUrl: "https://br.web.img2.acsta.net/pictures/19/04/29/20/14/1886009.jpg", displayName: "Megan Fox", gender: .cisFemale, age: 38)
    ]
    
    func verifyUserDiscoverability(token: String) async -> VerifyUserDiscoverabilityResponse? {
        if !discoverabilityVerified { isLoading = true }
        let result = await AYServices.shared.verifyUserDiscoverability(token: token)
        if !discoverabilityVerified { isLoading = false }
        
        switch result {
        case .success(let response):
            self.discoverabilityVerified = true
            return response
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
            return nil
        }
    }
    
    func activateUserDiscoverability(token: String, updateDiscoverStatus: (Bool) -> ()) async {
        isActivatingDiscover = true
        let result = await AYServices.shared.activateUserDiscoverability(token: token)
        isActivatingDiscover = false
        
        switch result {
        case .success:
            updateDiscoverStatus(true)
        case .failure(let error):
            if error == .unprocessableEntity {
                isPreferencesViewDisplayed = true
            } else {
                overlayError = (true, ErrorMessage.defaultErrorMessage)
            }
        }
    }
    
    func deactivatedUserDiscoverability(token: String, updateDiscoverStatus: (Bool) -> ()) async {
        isHidingAccount = true
        let result = await AYServices.shared.deactivateUserDiscoverability(token: token)
        isHidingAccount = false
        
        switch result {
        case .success:
            isPreferencesViewDisplayed = false
            updateDiscoverStatus(false)
        case .failure(let error):
            print("\(error)")
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
    }
    
    func updateUserPreferences(andActivateDiscover activateDiscover: Bool, token: String, updatePreferences: () -> (), updateDiscoverStatus: (Bool) -> ()) async {
        isSettingPreferences = true
        let result = await AYServices.shared.updateUserPreferences(gender: self.selectedGender.description, interestGenders: self.interestGendersAsStrings, age: self.selectedAge, minInterestAge: Int(self.ageRange.lowerBound), maxInterestAge: Int(self.ageRange.upperBound), token: token)
        isSettingPreferences = false
        
        switch result {
        case .success:
            isPreferencesViewDisplayed = false
            updatePreferences()
            if activateDiscover {
                await activateUserDiscoverability(token: token) { isDiscoverable in updateDiscoverStatus(isDiscoverable) }
            }
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
    }
    
    func areInputsValid() -> Bool {
        return !selectedInterestGenders.isEmpty
    }
}
