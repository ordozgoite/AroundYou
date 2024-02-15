//
//  FeedViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import Foundation

@MainActor
class FeedViewModel: ObservableObject {
    
    @Published var posts: [FormattedPost] = []
    @Published var isLoading: Bool = false
    @Published var isCommentScreenPresented = false
    
    func getPostsNearBy(latitude: Double, longitude: Double, token: String) async {
        isLoading = true
        let response = await AYServices.shared.getActivePublicationsNearBy(latitude: latitude, longitude: longitude, token: token)
        isLoading = false
        
        switch response {
        case .success(let posts):
            print(posts)
             self.posts = posts
        case .failure(let error):
            // Display error
            print("❌ Error: \(error)")
        }
    }
    
    func likePublication(publicationId: String, token: String) async {
        let response = await AYServices.shared.likePublication(publicationId: publicationId, token: token)
        
        switch response {
        case .success:
            print("❤️ Publication liked!")
        case .failure(let error):
            print("❌ Error: \(error)")
        }
    }
    
    func unlikePublication(publicationId: String, token: String) async {
        let response = await AYServices.shared.unlikePublication(publicationId: publicationId, token: token)
        
        switch response {
        case .success:
            print("💔 Publication unliked!")
        case .failure(let error):
            print("❌ Error: \(error)")
        }
    }
}
