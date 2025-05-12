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
    @Published var selectedCommunityDuration: CommunityDuration = .oneHour
    @Published var isLocationVisible: Bool = false
    @Published var isCommunityPrivate: Bool = false
    @Published var isCreatingCommunity: Bool = false
    @Published var overlayError: (Bool, LocalizedStringKey) = (false, "")
    
    // Community Image
    @Published var isImageOptionsDisplayed: Bool = false
    @Published var imageSelection: PhotosPickerItem?
    @Published var isCropViewDisplayed: Bool = false
    @Published var image: UIImage?
    @Published var croppedImage: UIImage?
    @Published var isPhotoPickerPresented: Bool = false
    
    func resetCreateCommunityInputs() {
        self.imageSelection = nil
        self.image = nil
        self.croppedImage = nil
        self.communityNameInput = ""
        communityDescriptionInput = ""
    }
    
    func areInputsValid() -> Bool {
        return !communityNameInput.isEmpty
    }
    
    func posNewCommunity(latitude: Double, longitude: Double, token: String, dismiss: () -> ()) async {
        isCreatingCommunity = true
        let imageUrl = self.croppedImage == nil ? nil : await getImageUrl()
        let result = await AYServices.shared.postNewCommunity(name: self.communityNameInput, description: self.communityDescriptionInput.isEmpty ? nil : self.communityDescriptionInput, duration: self.selectedCommunityDuration.value, isLocationVisible: self.isLocationVisible, isPrivate: self.isCommunityPrivate, imageUrl: imageUrl, latitude: latitude, longitude: longitude, token: token)
        isCreatingCommunity = false
        
        switch result {
        case .success:
            dismiss()
        case .failure(let error):
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
    
    private func loadTransferable(from imageSelection: PhotosPickerItem) -> Progress {
        return imageSelection.loadTransferable(type: Image.self) { result in
            DispatchQueue.main.async {
                guard imageSelection == self.imageSelection else { return }
                switch result {
                case .success(let image?):
                    print("✅ Success!")
                case .success(nil):
                    print("✅ Success!")
                case .failure(let error):
                    print("❌ Error: \(error)")
                    self.overlayError = (true, ErrorMessage.selectPhotoErrorMessage)
                }
            }
        }
    }
}
