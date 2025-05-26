//
//  EditBusinessViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 26/05/25.
//

import Foundation
import SwiftUI

@MainActor
class EditBusinessViewModel: ObservableObject {
    @Published var nameInput: String = ""
    @Published var descriptionInput: String = ""
    @Published var selectedCategory: BusinessCategory? = nil
    @Published var isEditing: Bool = false
    @Published var isLocationVisible: Bool = true
    @Published var phoneNumber: String = ""
    @Published var whatsAppNumber: String = ""
    @Published var instagramUsername: String = ""
    @Published var overlayError: (Bool, LocalizedStringKey) = (false, "")
    
    func editBusiness(businessId: String, token: String) async throws {
        isEditing = true
        defer { isEditing = false }
        
        let business = buildBusiness(withId: businessId)
        
        let result = await AYServices.shared.editBusiness(business: business, token: token)
        
        try handleEditBusinessResult(result)
    }
    
    private func handleEditBusinessResult(_ result: Result<Business, RequestError>) throws {
        switch result {
        case .success:
            print("✅ Business successfully edited.")
        case .failure(let error):
            overlayError = (true, "Error trying to edit Business. Please try again.")
            throw error
        }
    }
    
    private func buildBusiness(withId businessId: String) -> EditBusinessDTO {
        return EditBusinessDTO(
            businessId: businessId,
            description: self.descriptionInput.nonEmptyOrNil(),
            category: self.selectedCategory?.rawValue ?? "selling", // should never be nil
            isLocationVisible: self.isLocationVisible,
            title: self.nameInput,
            instagramUsername: self.instagramUsername.nonEmptyOrNil(),
            whatsAppNumber: self.whatsAppNumber.nonEmptyOrNil(),
            phoneNumber: self.phoneNumber.nonEmptyOrNil()
        )
    }
}
