//
//  AccountViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 16/02/24.
//

import Foundation

@MainActor
class AccountViewModel: ObservableObject {
    
    @Published var posts: [FormattedPost] = []
    @Published var selectedPostType: PostHistoryOption = .all
    @Published var newBioTextInput: String = ""
    @Published var isEditBioAlertPresented: Bool = false
    @Published var isLoadingposts: Bool = false
    @Published var overlayError: (Bool, String) = (false, "")
    
    func getUserPosts(token: String) async {
        isLoadingposts = true
        let response = await AYServices.shared.getAllPublicationsByUser(token: token)
        isLoadingposts = false
        
        switch response {
        case .success(let posts):
            self.posts = posts
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
    }
    
    func editBio(bio: String, token: String, updateBio: (String) -> ()) async {
        newBioTextInput = ""
        let response = await AYServices.shared.editBiography(biography: bio, token: token)
        
        switch response {
        case .success:
            updateBio(bio)
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
    }
    
    func deletePublication(publicationId: String, token: String) async {
        isLoadingposts = true
        let response = await AYServices.shared.deletePublication(publicationId: publicationId, token: token)
        isLoadingposts = false
        
        switch response {
        case .success:
            posts.removeAll { $0.id == publicationId }
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
    }
}
