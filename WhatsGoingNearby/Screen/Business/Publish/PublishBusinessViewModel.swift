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
    @Published var isImageOptionsDisplayed: Bool = false
    @Published var imageSelection: PhotosPickerItem?
    @Published var image: UIImage?
    @Published var isPhotoPickerPresented: Bool = false
    
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
            // TODO: display error
            // Verifique se o erro é de permissão e exiba a mensagem adequada!
            overlayError = (true, "Error trying to post Business.") // TODO: change!
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
            // TODO: Display Error
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
