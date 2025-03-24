//
//  FeedViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import Foundation
import SwiftUI

@MainActor
class PlacesViewModel: ObservableObject {
    
    @Published var posts: [FormattedPost] = []
    @Published var isLoading: Bool = false
    @Published var isCommentScreenPresented = false
    @Published var overlayError: (Bool, LocalizedStringKey) = (false, "")
    @Published var initialPostsFetched: Bool = false
    @Published var feedTimer: Timer?
    @Published var shouldUpdateFeed: Bool = true
    @Published var isLostAndFoundScreenDisplayed: Bool = false
    @Published var isReportScreenDisplayed: Bool = false
    @Published var isHelpViewDisplayed: Bool = false
    
    func getPosts(latitude: Double, longitude: Double, token: String) async {
        if !initialPostsFetched { isLoading = true }
        let response = await AYServices.shared.getAllPublicationsNearBy(latitude: latitude, longitude: longitude, token: token)
        if !initialPostsFetched { isLoading = false }
        
        switch response {
        case .success(let posts):
            updatePosts(with: posts)
            initialPostsFetched = true
        case .failure(let error):
            print("❌ Error: \(error)")
        }
    }
    
    private func updatePosts(with posts: [FormattedPost]) {
        if shouldUpdateFeed {
            self.posts = posts
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
