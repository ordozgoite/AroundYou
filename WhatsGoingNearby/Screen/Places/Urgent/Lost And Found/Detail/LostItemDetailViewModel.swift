//
//  LostItemDetailViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 01/05/25.
//

import Foundation
import SwiftUI

@MainActor
class LostItemDetailViewModel: ObservableObject {
    @Published var lostItem: LostItem? = nil
    @Published var isLoading: Bool = false
    @Published var overlayError: (Bool, LocalizedStringKey) = (false, "")
    
    func getLostItem(withId lostItemId: String, token: String) async {
        isLoading = true
        let result = await AYServices.shared.getLostItem(lostItemId: lostItemId, token: token)
        isLoading = false
        
        switch result {
        case .success(let lostItem):
            self.lostItem = lostItem
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
    }
    
    func setItemAsFound(lostItemId: String, token: String) async {
        let result = await AYServices.shared.setItemAsFound(lostItemId: lostItemId, token: token)
        
        // Vou tratar o resultado?
    }
}
