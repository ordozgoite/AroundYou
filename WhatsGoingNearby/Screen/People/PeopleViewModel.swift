//
//  DiscoveryViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 25/10/24.
//

import Foundation
import SwiftUI

@MainActor
class PeopleViewModel: ObservableObject {
    
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
    @Published var ageRange: ClosedRange<Double> = 12...40
    @Published var isDiscoverNotificationsEnabled: Bool = false
    
    // Discover
    @Published var isDiscoveringUsers: Bool = false
    @Published var initialUsersFetched: Bool = false
    @Published var usersFound: [UserDiscoverInfo] = []
    @Published var chatUser: Chat? = nil
    @Published var isMessageScreenDisplayed: Bool = false
    @Published var userToChatWith: UserDiscoverInfo? = nil
    @Published var discoverTimer: Timer?
    
    func verifyUserDiscoverability(token: String) async -> VerifyUserDiscoverabilityResponse? {
        if !discoverabilityVerified { isLoading = true }
        let result = await AYServices.shared.verifyUserDiscoverability(token: token)
        if !discoverabilityVerified { isLoading = false }
        
        switch result {
        case .success(let response):
            self.discoverabilityVerified = true
            return response
        case .failure:
            overlayError = (true, ErrorMessage.verifyUserDiscoverability)
            return nil
        }
    }
    
    func activateUserDiscoverability(token: String) async throws {
        isActivatingDiscover = true
        let result = await AYServices.shared.activateUserDiscoverability(token: token)
        isActivatingDiscover = false
        
        switch result {
        case .success:
            LocalState.agreedWithDiscoverDisclaimer = true
        case .failure(let error):
            if error == .unprocessableEntity {
                isPreferencesViewDisplayed = true
            } else {
                overlayError = (true, ErrorMessage.activateUserDiscoverability)
            }
            throw error
        }
    }
    
    func deactivatedUserDiscoverability(token: String) async throws {
        isHidingAccount = true
        let result = await AYServices.shared.deactivateUserDiscoverability(token: token)
        isHidingAccount = false
        
        switch result {
        case .success:
            isPreferencesViewDisplayed = false
        case .failure(let error):
            overlayError = (true, ErrorMessage.deactivateUserDiscoverability)
            throw error
        }
    }
    
    func updateUserPreferences(token: String) async throws {
        isSettingPreferences = true
        let result = await AYServices.shared.updateUserPreferences(gender: self.selectedGender.description, interestGenders: self.interestGendersAsStrings, age: self.selectedAge, minInterestAge: Int(self.ageRange.lowerBound), maxInterestAge: Int(self.ageRange.upperBound), isNotificationsEnabled: self.isDiscoverNotificationsEnabled, token: token)
        isSettingPreferences = false
        
        switch result {
        case .success:
            isPreferencesViewDisplayed = false
        case .failure(let error):
            overlayError = (true, ErrorMessage.updateUserPreferences)
            throw error
        }
    }
    
    func areInputsValid() -> Bool {
        return !selectedInterestGenders.isEmpty
    }
    
    func getUsersNearBy(latitude: Double, longitude: Double, token: String) async {
        if !initialUsersFetched { isDiscoveringUsers = true }
        let result = await AYServices.shared.discoverUsersByPreferences(latitude: latitude, longitude: longitude, token: token)
        if !initialUsersFetched { isDiscoveringUsers = false }
        
        switch result {
        case .success(let users):
            self.usersFound = users
            self.initialUsersFetched = true
        case .failure:
            overlayError = (true, ErrorMessage.getUsersNearBy)
        }
    }
    
    func postNewChat(otherUserUid: String, token: String) async {
        let result = await AYServices.shared.postNewChat(otherUserUid: otherUserUid, token: token)
        
        switch result {
        case .success(let chat):
            self.chatUser = chat
            self.isMessageScreenDisplayed = true
        case .failure:
            overlayError = (true, ErrorMessage.postNewChat)
        }
    }
}
