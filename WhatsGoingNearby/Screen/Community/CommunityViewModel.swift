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
    @Published var communities: [Community] = [
//        Community(id: "1", name: "Show Guns N' Roses", imageUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTdLXpuHHbuLb1QC4u4XkaqR50h4BBEqnJ1Sw&s", description: nil, latitude: 0, longitude: 0, isMember: false, isPrivate: false),
//        Community(id: "2", name: "Condomínio Anaíra", imageUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTkXlQ58pctqQXj92LWf2VVylZh5dYLNCsnzA&s", description: nil, latitude: 0, longitude: 0, isMember: false, isPrivate: true),
//        Community(id: "3",name: "Alcoólicos Anônimos", imageUrl: nil, description: nil, latitude: 0, longitude: 0, isMember: false, isPrivate: false),
//        Community(id: "4", name: "Caçadores de Pokemon", imageUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS5-8Chu2Jala7WIXFNYCt4PY78NzZng1MVcw&s", description: nil, latitude: 0, longitude: 0, isMember: false, isPrivate: false)
    ]
    @Published var isLoading: Bool = false
    
    // Create Community
    @Published var communityNameInput: String = ""
    @Published var communityDescriptionInput: String = ""
    @Published var isCreatingCommunity: Bool = false
    @Published var isCreateCommunityViewDisplayed: Bool = false
    @Published var latitude: Double = 0
    @Published var longitude: Double = 0
    @Published var selectedCommunityDuration: CommunityDuration = .oneHour
    @Published var isLocationVisible: Bool = false
    @Published var overlayError: (Bool, LocalizedStringKey) = (false, "")
    @Published var isCommunityPrivate: Bool = false
    @Published var image: UIImage?
    @Published var isCameraDisplayed = false
    
    func resetCreateCommunityInputs() {
        // TODO: Remove image
        self.communityNameInput = ""
        communityDescriptionInput = ""
    }
    
    func posNewCommunity(latitude: Double, longitude: Double, token: String) async {
        isCreatingCommunity = true
        // TODO: Store Image if necessary
        
        var imageUrl: String?
        let result = await AYServices.shared.postNewCommunity(name: self.communityNameInput, description: self.communityDescriptionInput.isEmpty ? nil : self.communityDescriptionInput, duration: self.selectedCommunityDuration.value, isLocationVisible: self.isLocationVisible, isPrivate: self.isCommunityPrivate, imageUrl: imageUrl, latitude: latitude, longitude: longitude, token: token)
        isCreatingCommunity = false
        
        switch result {
        case .success:
            isCreateCommunityViewDisplayed = false
        case .failure(let error):
            // TODO: Display error
            print("Error: \(error)")
        }
    }
}
