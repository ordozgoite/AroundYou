//
//  NewPostViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 14/02/24.
//

import Foundation

@MainActor
class NewPostViewModel: ObservableObject {
    
    @Published var postText: String = ""
    @Published var isLoading: Bool = false
    
    func postNewPublication(latitude: Double, longitude: Double, token: String, dismissScreen: () -> ()) async {
            isLoading = true
            let result = await AYServices.shared.postNewPublication(text: postText, latitude: latitude, longitude: longitude, token: token)
            isLoading = false
            
            switch result {
            case .success:
                dismissScreen()
            case .failure(let error):
                // Display error
                print("❌ Error: \(error)")
            }
    }
}
