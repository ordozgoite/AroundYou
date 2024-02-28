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
            // update enviroment
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
        case .success:
            await getUserInfo(token: token)
            isSuccessAlertDisplayed = true
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
    }
    
    func storeImage(forUser userUid: String, token: String) async throws -> String? {
        isStoringPhoto = true
        guard croppedImage != nil else { return nil }
        let storageRef = Storage.storage().reference()
        let fileRef = storageRef.child("profile-pic/\(userUid).jpg")
        
        let imageData = croppedImage?.jpegData(compressionQuality: 0.8)
        _ = try await fileRef.putDataAsync(imageData!)
        
        let imageUrl = try await fileRef.downloadURL()
        let profile = UserProfileDTO(name: nil, profilePic: imageUrl.absoluteString, biography: nil)
        
        let result = await AYServices.shared.editProfile(profile: profile, token: token)
        isStoringPhoto = false
        
        switch result {
        case .success:
            await getUserInfo(token: token)
            return imageUrl.absoluteString
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
        nameInput = user.name
        bioInput = user.biography ?? ""
        if let url = user.profilePic {
            profilePicUrl = url
        } else {
            profilePicUrl = nil
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
