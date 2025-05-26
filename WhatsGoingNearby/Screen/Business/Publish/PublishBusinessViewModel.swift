//
//  PublishBusinessViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 02/03/25.
//

import Foundation
import SwiftUI
import PhotosUI

@MainActor
class PublishBusinessViewModel: ObservableObject {
    
    @Published var nameInput: String = ""
    @Published var descriptionInput: String = ""
    @Published var selectedCategory: BusinessCategory? = nil
    @Published var isLoading: Bool = false
    @Published var isLocationVisible: Bool = true
    @Published var phoneNumber: String = ""
    @Published var whatsAppNumber: String = ""
    @Published var instagramUsername: String = ""
    @Published var overlayError: (Bool, LocalizedStringKey) = (false, "")
    
    // Business Image
    @Published var isCameraPickerDisplayed: Bool = false
    @Published var isPhotoPickerDisplayed: Bool = false
    @Published var image: UIImage?
    
    func publishBusiness(location: Location, token: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let imageUrl = self.image == nil ? nil : await getImageUrl()
        let business = createBusiness(location: location, imageUrl: imageUrl)
        let result = await AYServices.shared.postNewBusiness(business: business, token: token)
        
        switch result {
        case .success:
            print("✅ Business successfully published!")
        case .failure(let error):
            if error == .locked {
                overlayError = (true, ErrorMessage.businessesPublishedLimitExceeded)
            } else {
                overlayError = (true, ErrorMessage.publishBusiness)
            }
        }
    }
    
    private func createBusiness(location: Location, imageUrl: String?) -> Business {
        return Business(
            title: nameInput,
            description: descriptionInput.nonEmptyOrNil(),
            imageUrl: imageUrl, category: selectedCategory!.rawValue,
            latitude: location.latitude, longitude: location.longitude,
            isLocationVisible: self.isLocationVisible,
            phoneNumber: self.phoneNumber.normalizePhoneNumber().nonEmptyOrNil(),
            whatsAppNumber: self.whatsAppNumber.normalizePhoneNumber().nonEmptyOrNil(),
            instagramUsername: self.instagramUsername.nonEmptyOrNil()
        )
    }
    
    private func getImageUrl() async -> String? {
        do {
            return try await FirebaseService.shared.storeImageAndGetUrl(self.image!)
        } catch {
            overlayError = (true, ErrorMessage.postImageErrorMessage)
            return nil
        }
    }}
