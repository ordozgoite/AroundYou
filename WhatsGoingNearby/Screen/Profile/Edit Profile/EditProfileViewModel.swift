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
    
    @Published var usernameInput: String = ""
    @Published var nameInput: String = ""
    @Published var bioInput: String = ""
    @Published var profilePicUrl: String?
    
    @Published var isLoading: Bool = false
    @Published var isEditingProfile: Bool = false
    @Published var isStoringPhoto: Bool = false
    @Published var isRemovingPhoto: Bool = false
    
    @Published var isSuccessAlertDisplayed: Bool = false
    @Published var isChangeAlertDisplayed: Bool = false
    @Published var overlayError: (Bool, LocalizedStringKey) = (false, "")
    
    // Profile Image
    @Published var imageSelection: PhotosPickerItem?
    @Published var selectedImage: UIImage?
    @Published var croppedImage: UIImage?
    @Published var isCropViewDisplayed: Bool = false
    
    func getUserInfo(token: String) async {
        isLoading = true
        let result = await AYServices.shared.getUserInfo(token: token)
        isLoading = false
        
        switch result {
        case .success(let user):
            updateInfo(forUser: user)
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
    }
    
    func editProfile(token: String) async -> Bool {
        if !validateUsername() {
            overlayError = (true, ErrorMessage.invalidUsernameMessage)
            return false
        }
        
        let profile = UserProfileDTO(username: usernameInput, name: nameInput.isEmpty ? nil : nameInput, profilePic: nil, biography: bioInput.isEmpty ? nil : bioInput)
        
        isEditingProfile = true
        let result = await AYServices.shared.editProfile(profile: profile, token: token)
        isEditingProfile = false
        
        switch result {
        case .success:
            await getUserInfo(token: token)
            isSuccessAlertDisplayed = true
            return true
        case .failure(let error):
            if error == .conflict {
                overlayError = (true, ErrorMessage.usernameInUseMessage)
            } else {
                overlayError = (true, ErrorMessage.defaultErrorMessage)
            }
        }
        return false
    }
    
    func storeImageAndGetUrl(forUser userUid: String, token: String) async throws -> String? {
        isStoringPhoto = true
        guard croppedImage != nil else { return nil }
        let imageUrl = try await FirebaseService.shared.storeImageAndGetUrl(croppedImage!)
        let profile = UserProfileDTO(username: nil, name: nil, profilePic: imageUrl, biography: nil)
        let result = await AYServices.shared.editProfile(profile: profile, token: token)
        isStoringPhoto = false
        
        switch result {
        case .success:
            await getUserInfo(token: token)
            return imageUrl
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
        return nil
    }
    
    func removePhoto(token: String) async {
        isRemovingPhoto = true
        let result = await AYServices.shared.deleteProfilePic(token: token)
        isRemovingPhoto = false
        
        switch result {
        case .success:
            await getUserInfo(token: token)
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
    }
    
    private func updateInfo(forUser user: MongoUser) {
        usernameInput = user.username
        nameInput = user.name ?? ""
        bioInput = user.biography ?? ""
        if let url = user.profilePic {
            profilePicUrl = url
        } else {
            profilePicUrl = nil
        }
    }
    
    private func validateUsername() -> Bool {
        let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._")
        return usernameInput.rangeOfCharacter(from: allowedCharacters.inverted) == nil
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
