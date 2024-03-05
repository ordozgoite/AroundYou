//
//  NewPostViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 14/02/24.
//

import Foundation
import SwiftUI

@MainActor
class NewPostViewModel: ObservableObject {
    
    @Published var postText: String = ""
    @Published var isLoading: Bool = false
    @Published var overlayError: (Bool, LocalizedStringKey) = (false, "")
    @Published var selectedPostLocationVisibilty: PostLocationVisibility = .hidden {
        didSet {
            LocalState.isPostLocationVisible = selectedPostLocationVisibilty == .visible
        }
    }
    @Published var isShareLocationAlertDisplayed: Bool = false
    
    func postNewPublication(latitude: Double, longitude: Double, token: String, dismissScreen: () -> ()) async {
            isLoading = true
        let result = await AYServices.shared.postNewPublication(text: postText, latitude: latitude, longitude: longitude, isLocationVisible: selectedPostLocationVisibilty.isLocationVisible, token: token)
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
}
