//
//  NewPostViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 14/02/24.
//

import Foundation

enum PostVisibility: CaseIterable {
    case identified
    case anonymous
    
    var title: String {
        switch self {
        case .identified:
            return "Identified"
        case .anonymous:
            return "Anonymous"
        }
    }
}

@MainActor
class NewPostViewModel: ObservableObject {
    
//    @Published var postText: String = ""
    @Published var selectedPostVisibility: PostVisibility = .identified
    @Published var isLoading: Bool = false
    
    func postNewPublication(text: String, latitude: Double, longitude: Double, token: String, completionHandler: () -> ()) async {
        isLoading = true
        let result = await AYServices.shared.postNewPublication(text: text, latitude: latitude, longitude: longitude, token: token)
        isLoading = false
        
        switch result {
        case .success:
            completionHandler()
        case .failure(let error):
            // Display error
            print("❌ Error: \(error)")
        }
    }
    
}
