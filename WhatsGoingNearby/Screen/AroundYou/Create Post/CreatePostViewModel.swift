//
//  NewPostViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 14/02/24.
//

import Foundation
import SwiftUI
import FirebaseStorage

@MainActor
class CreatePostViewModel: ObservableObject {
    
    @Published var postText: String = ""
    @Published var isLoading: Bool = false
    @Published var overlayError: (Bool, LocalizedStringKey) = (false, "")
    @Published var isLocationVisible: Bool = false
    @Published var selectedPostTag: PostTag = .chilling
    @Published var selectedPostDuration: PostDuration = .oneHour
    @Published var isShareLocationAlertDisplayed: Bool = false
    @Published var isSettingsExpanded: Bool = false
    
    @Published var image: UIImage?
    @Published var isCameraDisplayed = false
    
    func postNewPublication(latitude: Double, longitude: Double, token: String, dismissScreen: () -> ()) async {
        isLoading = true
        let imageURL = image == nil ? nil : await storeImage()
        let result = await AYServices.shared.postNewPublication(text: postText.nonEmptyOrNil(), tag: selectedPostTag.rawValue, imageUrl: imageURL, postDuration: selectedPostDuration.value, latitude: latitude, longitude: longitude, isLocationVisible: isLocationVisible, token: token)
        isLoading = false
        
        switch result {
        case .success:
            dismissScreen()
        case .failure(let error):
            if error == .forbidden {
                overlayError = (true, ErrorMessage.publicationLimitExceededErrorMessage)
            } else {
                overlayError = (true, ErrorMessage.defaultErrorMessage)
            }
        }
    }
    
    private func storeImage() async -> String? {
        do {
            return try await FirebaseService.shared.storeImageAndGetUrl(self.image!)
        } catch {
            overlayError = (true, ErrorMessage.defaultErrorMessage)
            isLoading = false
            return nil
        }
    }
}
