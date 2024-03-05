//
//  BugViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 17/02/24.
//

import Foundation
import SwiftUI

@MainActor
class BugViewModel: ObservableObject {
    
    let maxDescriptionLenght = 500
    @Published var descriptionTextInput: String = ""
    @Published var isPostingReport: Bool = false
    @Published var overlayError: (Bool, LocalizedStringKey) = (false, "")
    
    func postReport(token: String, dismissScreen: () -> ()) async {
        isPostingReport = true
        let response = await AYServices.shared.postNewBugReport(bugDescription: descriptionTextInput, token: token)
        isPostingReport = false
        
        switch response {
        case .success:
            dismissScreen()
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
    }
}
