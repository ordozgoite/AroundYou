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
    @Published var isGettingLostItem: Bool = false
    @Published var isSettingItemAsLost: Bool = false
    @Published var overlayError: (Bool, LocalizedStringKey) = (false, "")
    
    func getLostItem(withId lostItemId: String, token: String) async {
        isGettingLostItem = true
        defer { isGettingLostItem = false }
        let result = await AYServices.shared.getLostItem(lostItemId: lostItemId, token: token)
        handleGetLostItemResult(result)
    }
    
    private func handleGetLostItemResult(_ result: Result<LostItem, RequestError>) {
        switch result {
        case .success(let lostItem):
            self.lostItem = lostItem
        case .failure:
            overlayError = (true, "Error trying to fetch lost item info.")
        }
    }
    
    func setItemAsFound(lostItemId: String, token: String) async {
        isSettingItemAsLost = true
        defer { isSettingItemAsLost = false }
        let result = await AYServices.shared.setItemAsFound(lostItemId: lostItemId, token: token)
        handleSetItemAsFoundResult(result)
    }
    
    private func handleSetItemAsFoundResult(_ result: Result<SuccessMessageResponse, RequestError>) {
        switch result {
        case .success:
            self.lostItem?.wasFound = true
        case .failure:
            overlayError = (true, "Error trying to set item as 'found'.")
        }
    }
}
