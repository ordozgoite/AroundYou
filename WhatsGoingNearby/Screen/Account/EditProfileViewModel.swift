//
//  EditProfileViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 17/02/24.
//

import Foundation
import PhotosUI
import SwiftUI
import FirebaseStorage

@MainActor
class EditProfileViewModel: ObservableObject {
    
    let maxNameLenght = 50
    let maxBioLenght = 250
    
    @Published var nameInput: String = ""
    @Published var bioInput: String = ""
    @Published var isEditingProfile: Bool = false
    @Published var isStoringPhoto: Bool = false
    @Published var isSuccessAlertDisplayed: Bool = false
    @Published var isActionSheetDisplayed: Bool = false
    @Published var overlayError: (Bool, String) = (false, "")
    
    // Profile Image
    
    enum ImageState {
        case empty, loading(Progress), success(Image), failure(Error), stored
    }
    
    @Published var imageState: ImageState = .empty
    @Published var imageSelection: PhotosPickerItem? {
        didSet {
            if let imageSelection {
                let progress = loadTransferable(from: imageSelection)
                imageState = .loading(progress)
            } else {
                imageState = .empty
            }
        }
    }
    @Published var imageData: Data? = nil
    
    private func loadTransferable(from imageSelection: PhotosPickerItem) -> Progress {
        return imageSelection.loadTransferable(type: Image.self) { result in
            DispatchQueue.main.async {
                guard imageSelection == self.imageSelection else { return }
                switch result {
                case .success(let image?):
                    self.imageState = .success(image)
                case .success(nil):
                    self.imageState = .empty
                case .failure(let error):
                    self.imageState = .failure(error)
                }
            }
        }
    }
    
    func editProfile(token: String, updateUserData: (EditProfileResponse) -> ()) async {
        let profile = UserProfileDTO(name: nameInput.isEmpty ? nil : nameInput, profilePic: nil, biography: bioInput.isEmpty ? nil : bioInput)
        
        isEditingProfile = true
        let result = await AYServices.shared.editProfile(profile: profile, token: token)
        isEditingProfile = false
        
        switch result {
        case .success(let response):
            updateUserData(response)
            isSuccessAlertDisplayed = true
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
    }
    
    func storeImage(forUser userUid: String, token: String, updateUserData: (EditProfileResponse) -> ()) async throws {
        isStoringPhoto = true
        guard imageData != nil else { return }
        let storageRef = Storage.storage().reference()
        let fileRef = storageRef.child("profile-pic/\(userUid).jpg")
        
        _ = try await fileRef.putDataAsync(self.imageData!)
        
        let imageUrl = try await fileRef.downloadURL()
        let profile = UserProfileDTO(name: nil, profilePic: imageUrl.absoluteString, biography: nil)
        
        let result = await AYServices.shared.editProfile(profile: profile, token: token)
        isStoringPhoto = false
        
        switch result {
        case .success(let response):
            updateUserData(response)
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
    }
}
