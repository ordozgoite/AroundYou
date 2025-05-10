//
//  AccountViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 16/02/24.
//

import Foundation
import SwiftUI

@MainActor
class AccountViewModel: ObservableObject {
    
    @Published var posts: [FormattedPost] = []
    @Published var selectedPostType: PostHistoryOption = .all
    @Published var newBioTextInput: String = ""
    @Published var isEditProfileScreenPresented: Bool = false
    @Published var overlayError: (Bool, LocalizedStringKey) = (false, "")
    
    func getUserPosts(location:  Location, token: String) async {
        let response = await AYServices.shared.getAllPublicationsByUser(latitude: location.latitude, longitude: location.longitude, token: token)
        
        switch response {
        case .success(let posts):
            self.posts = posts
        case .failure:
            overlayError = (true, ErrorMessage.getUserPosts)
        }
    }
    
    func deletePublication(publicationId: String, token: String) async {
        let response = await AYServices.shared.deletePublication(publicationId: publicationId, token: token)
        
        switch response {
        case .success:
            posts.removeAll { $0.id == publicationId }
        case .failure:
            overlayError = (true, ErrorMessage.deletePost)
        }
    }
}
