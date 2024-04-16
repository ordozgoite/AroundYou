//
//  EditPostViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 02/04/24.
//

import Foundation
import SwiftUI

@MainActor
class EditPostViewModel: ObservableObject {
    
    @Published var postText: String = ""
    @Published var isLoading: Bool = false
    @Published var overlayError: (Bool, LocalizedStringKey) = (false, "")
    @Published var selectedPostLocationVisibilty: PostLocationVisibility = .hidden
    @Published var selectedPostTag: PostTag = .chat
    @Published var selectedPostDuration: PostDuration = .fourHours
    @Published var isShareLocationAlertDisplayed: Bool = false
    
    func editPublication(publicationId: String, latitude: Double, longitude: Double, token: String, dismissScreen: () -> ()) async {
        isLoading = true
        let result = await AYServices.shared.editPublication(publicationId: publicationId, text: postText.nonEmptyOrNil(), tag: selectedPostTag.rawValue, postDuration: selectedPostDuration.value, isLocationVisible: selectedPostLocationVisibilty.isLocationVisible, latitude: latitude, longitude: longitude, token: token)
        isLoading = false
        
        switch result {
        case .success:
            dismissScreen()
        case .failure(let error):
            if error == .forbidden {
                overlayError = (true, ErrorMessage.editDistanceLimitExceededErrorMessage)
            } else {
                overlayError = (true, ErrorMessage.defaultErrorMessage)
            }
        }
    }
}
