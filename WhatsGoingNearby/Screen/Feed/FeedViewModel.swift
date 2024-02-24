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
    @Published var overlayError: (Bool, String) = (false, "")
    @Published var initialPostsFetched: Bool = false
    @Published var timer: Timer?
    @Published var feedTimer: Timer?
    @Published var currentTimeStamp: Int = Int(Date().timeIntervalSince1970)
    
    func getPostsNearBy(latitude: Double, longitude: Double, token: String) async {
        initialPostsFetched = true
        isLoading = true
        let response = await AYServices.shared.getActivePublicationsNearBy(latitude: latitude, longitude: longitude, token: token)
        isLoading = false
        
        switch response {
        case .success(let posts):
             self.posts = posts
        case .failure(let error):
            print("❌ Error: \(error)")
        }
    }
    
    func deletePublication(publicationId: String, token: String) async {
        isLoading = true
        let response = await AYServices.shared.deletePublication(publicationId: publicationId, token: token)
        isLoading = false
        
        switch response {
        case .success:
            posts.removeAll { $0.id == publicationId }
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
    }
}
