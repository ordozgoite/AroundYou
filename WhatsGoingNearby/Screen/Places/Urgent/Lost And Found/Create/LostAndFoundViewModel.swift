//
//  LostAndFoundViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 09/04/25.
//

import SwiftUI
import PhotosUI

enum PostLostItemError: Error {
    case genericError
}

@MainActor
class LostAndFoundViewModel: ObservableObject {
    @Published var itemName: String = ""
    @Published var itemDescription: String = ""
    @Published var lostLocationDescription: String = ""
    @Published var lostItemCoordinate: CLLocationCoordinate2D?
    @Published var lostDate: Date = Date()
    @Published var rewardOffer: Bool = false
    @Published var isPostingItem: Bool = false
    @Published var overlayError: (Bool, LocalizedStringKey) = (false, "")
    @Published var imageSelection: PhotosPickerItem? = nil
    @Published var selectedImage: UIImage? = nil
    
    func postLostItem(location: Location, token: String) async throws {
        isPostingItem = true
        defer { isPostingItem = false }
        
        let imageUrl = await getImageUrl()
        let lostItemObject = makeLostItem(withImageUrl: imageUrl, location: location)
        let result = await AYServices.shared.postLostItem(lostItem: lostItemObject, token: token)
        
        try handlePostResult(result)
    }
    
    private func getImageUrl() async -> String? {
        guard let image = self.selectedImage else { return nil }
        do {
            return try await FirebaseService.shared.storeImageAndGetUrl(image)
        } catch {
            // TODO: Display Error
            return nil
        }
    }
    
    private func makeLostItem(withImageUrl imageUrl: String?, location: Location) -> LostItem {
        return LostItem(
            id: UUID().uuidString,
            name: self.itemName,
            description: self.itemDescription.nonEmptyOrNil(),
            imageUrl: imageUrl,
            locationDescription: self.lostLocationDescription.nonEmptyOrNil(),
            latitude: location.latitude,
            longitude: location.longitude,
            lostDate: Int(self.lostDate.timeIntervalSince1970 * 1000), // JavaScript usa timestamp em milisegundos
            hasReward: self.rewardOffer,
            wasFound: false,
            userUid: nil
        )
    }
    
    private func handlePostResult(_ result: Result<SuccessMessageResponse, RequestError>) throws {
        switch result {
        case .success:
            print("✅ Lost Item successfully posted!")
        case .failure:
            // TODO: Display Error
            throw PostLostItemError.genericError
        }
    }
    
    func isSubmitButtonEnabled() -> Bool {
        return !self.itemName.isEmpty && self.lostItemCoordinate != nil
    }
    
    func removePhoto() {
        self.imageSelection = nil
        self.selectedImage = nil
    }
}
