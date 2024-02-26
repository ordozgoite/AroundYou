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
    @Published var profilePicUrl: String?
    
    @Published var isLoading: Bool = false
    @Published var isEditingProfile: Bool = false
    @Published var isStoringPhoto: Bool = false
    
    @Published var isSuccessAlertDisplayed: Bool = false
    @Published var isActionSheetDisplayed: Bool = false
    @Published var overlayError: (Bool, String) = (false, "")
    
    // Profile Image
    @Published var imageSelection: PhotosPickerItem?
    @Published var imageData: Data? = nil
    
    func getUserInfo(token: String) async {
        isLoading = true
        let result = await AYServices.shared.getUserInfo(token: token)
        isLoading = false
        
        switch result {
        case .success(let user):
            nameInput = user.name
            bioInput = user.biography ?? ""
            if let url = user.profilePic {
                profilePicUrl = url
            }
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
    }
    
    func editProfile(token: String) async {
        let profile = UserProfileDTO(name: nameInput.isEmpty ? nil : nameInput, profilePic: nil, biography: bioInput.isEmpty ? nil : bioInput)
        
        isEditingProfile = true
        let result = await AYServices.shared.editProfile(profile: profile, token: token)
        isEditingProfile = false
        
        switch result {
        case .success(let response):
            await getUserInfo(token: token)
            isSuccessAlertDisplayed = true
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
    }
    
    func storeImage(forUser userUid: String, token: String) async throws {
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
            await getUserInfo(token: token)
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
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
                }
            }
        }
    }
}
