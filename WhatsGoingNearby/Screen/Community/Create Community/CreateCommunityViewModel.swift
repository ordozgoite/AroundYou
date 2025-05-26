//
//  CreateCommunityViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 08/02/25.
//

import Foundation
import SwiftUI
import PhotosUI

@MainActor
class CreateCommunityViewModel: ObservableObject {
    
    @Published var communityNameInput: String = ""
    @Published var communityDescriptionInput: String = ""
    @Published var isLocationVisible: Bool = false
    @Published var isCommunityPrivate: Bool = false
    @Published var isCreatingCommunity: Bool = false
    @Published var overlayError: (Bool, LocalizedStringKey) = (false, "")
    @Published var isDurationInfoPopoverDisplayed: Bool = false
    
    // Community Image
    @Published var isCameraPickerDisplayed: Bool = false
    @Published var isPhotoPickerDisplayed: Bool = false
    @Published var isCropViewDisplayed: Bool = false
    @Published var imageFromCamera: UIImage?
    @Published var imageFromAlbum: UIImage?
    @Published var croppedImage: UIImage?
    
    func areInputsValid() -> Bool {
        return !communityNameInput.isEmpty
    }
    
    func posNewCommunity(latitude: Double, longitude: Double, token: String) async {
        isCreatingCommunity = true
        let imageUrl = self.croppedImage == nil ? nil : await getImageUrl()
        let result = await AYServices.shared.postNewCommunity(name: self.communityNameInput, description: self.communityDescriptionInput.isEmpty ? nil : self.communityDescriptionInput, isLocationVisible: self.isLocationVisible, isPrivate: self.isCommunityPrivate, imageUrl: imageUrl, latitude: latitude, longitude: longitude, token: token)
        isCreatingCommunity = false
        
        switch result {
        case .success:
            print("✅ New Community successfully posted!")
        case .failure:
            overlayError = (true, ErrorMessage.postNewCommunity)
        }
    }
    
    private func getImageUrl() async -> String? {
        do {
            return try await FirebaseService.shared.storeImageAndGetUrl(self.croppedImage!)
        } catch {
            overlayError = (true, ErrorMessage.postImageErrorMessage)
            return nil
        }
    }
}
