//
//  LikeViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 22/02/24.
//

import Foundation

@MainActor
class LikeViewModel: ObservableObject {
    
    @Published var users: [UserProfile] = []
    @Published var isLoading: Bool = false
    @Published var overlayError: (Bool, String) = (false, "")
    
    func getPublicationLikes(publicationId: String, token: String) async {
        isLoading = true
        let result = await AYServices.shared.getPublicationLikes(publicationId: publicationId, token: token)
        isLoading = false
        
        switch result {
        case .success(let users):
            self.users = users
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
    }
}
