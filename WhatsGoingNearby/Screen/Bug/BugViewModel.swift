//
//  BugViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 17/02/24.
//

import Foundation

@MainActor
class BugViewModel: ObservableObject {
    
    let maxDescriptionLenght = 500
    @Published var descriptionTextInput: String = ""
    @Published var isPostingReport: Bool = false
    @Published var overlayError: (Bool, String) = (false, "")
    
    func postReport(token: String, dismissScreen: () -> ()) async {
        
    }
}
