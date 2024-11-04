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

struct UserDiscoverInfo: Codable, Identifiable {
    let id: String
    let imageUrl: String?
    let displayName: String
    let gender: String
    let age: Int
}

@MainActor
class DiscoverViewModel: ObservableObject {
    
    @Published var isLoading: Bool = false
    @Published var isActivatingDiscover: Bool = false
    @Published var isDiscoverable: Bool = false
    @Published var overlayError: (Bool, LocalizedStringKey) = (false, "")
    @Published var isPreferencesViewDisplayed: Bool = false
    
    // Preferences
    @Published var isSettingPreferences: Bool = false
    @Published var isHidingAccount: Bool = false
    @Published var selectedGender: Gender = .male
    @Published var selectedInterestGender: InterestGender = .everyone
    @Published var selectedAge: Int = 18
    @Published var ageRange: ClosedRange<Double> = 18...40
    
    // Discover
    @Published var usersFound: [UserDiscoverInfo] = [
        UserDiscoverInfo(id: "1", imageUrl: "https://br.web.img2.acsta.net/pictures/19/04/29/20/14/1886009.jpg", displayName: "Megan Fox", gender: "female", age: 38),
        UserDiscoverInfo(id: "2", imageUrl: "https://br.web.img2.acsta.net/pictures/19/04/29/20/14/1886009.jpg", displayName: "Megan Fox", gender: "female", age: 38),
        UserDiscoverInfo(id: "3", imageUrl: "https://br.web.img2.acsta.net/pictures/19/04/29/20/14/1886009.jpg", displayName: "Megan Fox", gender: "female", age: 38),
        UserDiscoverInfo(id: "4", imageUrl: "https://br.web.img2.acsta.net/pictures/19/04/29/20/14/1886009.jpg", displayName: "Megan Fox", gender: "female", age: 38),
        UserDiscoverInfo(id: "5", imageUrl: "https://br.web.img2.acsta.net/pictures/19/04/29/20/14/1886009.jpg", displayName: "Megan Fox", gender: "female", age: 38)
    ]
    
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
    
    func activateUserDiscoverability(token: String) async {
        isActivatingDiscover = true
        let result = await AYServices.shared.activateUserDiscoverability(token: token)
        isActivatingDiscover = false
        
        switch result {
        case .success:
            self.isDiscoverable = true
        case .failure(let error):
            if error == .unprocessableEntity {
                isPreferencesViewDisplayed = true
            } else {
                overlayError = (true, ErrorMessage.defaultErrorMessage)
            }
        }
    }
    
    func deactivatedUserDiscoverability(token: String) async {
        isHidingAccount = true
        let result = await AYServices.shared.deactivateUserDiscoverability(token: token)
        isHidingAccount = false
        
        switch result {
        case .success:
            isPreferencesViewDisplayed = false
            isDiscoverable = false
        case .failure(let error):
            print("\(error)")
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
    }
    
    func updateUserPreferences(token: String) async {
        isSettingPreferences = true
        let result = await AYServices.shared.updateUserPreferences(gender: self.selectedGender.rawValue, interestGender: self.selectedInterestGender.rawValue, age: self.selectedAge, minInterestAge: Int(self.ageRange.lowerBound), maxInterestAge: Int(self.ageRange.upperBound), token: token)
        isSettingPreferences = false
        
        switch result {
        case .success:
            isPreferencesViewDisplayed = false
            if !isDiscoverable {
                await activateUserDiscoverability(token: token)
            }
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
    }
}
