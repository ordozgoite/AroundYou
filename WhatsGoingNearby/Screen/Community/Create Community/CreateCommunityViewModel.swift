//
//  CreateCommunityViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 08/02/25.
//

import Foundation
import SwiftUI

@MainActor
class CreateCommunityViewModel: ObservableObject {
    
    @Published var communityNameInput: String = ""
    @Published var communityDescriptionInput: String = ""
    @Published var isCreatingCommunity: Bool = false
    @Published var latitude: Double = 0
    @Published var longitude: Double = 0
    @Published var selectedCommunityDuration: CommunityDuration = .oneHour
    @Published var isLocationVisible: Bool = false
    @Published var overlayError: (Bool, LocalizedStringKey) = (false, "")
    @Published var isCommunityPrivate: Bool = false
    @Published var image: UIImage?
    @Published var isCameraDisplayed = false
    
    func resetCreateCommunityInputs() {
        // TODO: Remove Image
        self.communityNameInput = ""
        communityDescriptionInput = ""
    }
    
    func posNewCommunity(latitude: Double, longitude: Double, token: String, dismiss: () -> ()) async {
        isCreatingCommunity = true
        let imageUrl = self.image == nil ? nil : await getImageUrl()
        let result = await AYServices.shared.postNewCommunity(name: self.communityNameInput, description: self.communityDescriptionInput.isEmpty ? nil : self.communityDescriptionInput, duration: self.selectedCommunityDuration.value, isLocationVisible: self.isLocationVisible, isPrivate: self.isCommunityPrivate, imageUrl: imageUrl, latitude: latitude, longitude: longitude, token: token)
        isCreatingCommunity = false
        
        switch result {
        case .success:
            dismiss()
        case .failure(let error):
            // TODO: Display error
            print("Error: \(error)")
        }
    }
    
    private func getImageUrl() async -> String? {
        do {
            return try await FirebaseService.shared.storeImageAndGetUrl(self.image!)
        } catch {
            // TODO: Display Error
            return nil
        }
    }
}
