//
//  EditProfileViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 17/02/24.
//

import Foundation

@MainActor
class EditProfileViewModel: ObservableObject {
    
    let maxNameLenght = 50
    let maxBioLenght = 250
    
    @Published var nameInput: String = ""
    @Published var bioInput: String = ""
    @Published var isLoading: Bool = false
    @Published var isSuccessAlertDisplayed: Bool = false
    @Published var overlayError: (Bool, String) = (false, "")
    
    func editProfile(token: String, updateUserData: (EditProfileResponse) -> ()) async {
        isLoading = true
        let result = await AYServices.shared.editProfile(name: nameInput, biography: bioInput, token: token)
        isLoading = false
        
        switch result {
        case .success(let response):
            updateUserData(response)
            isSuccessAlertDisplayed = true
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
    }
}
