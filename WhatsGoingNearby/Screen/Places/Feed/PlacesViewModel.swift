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
    @Published var navigationTarget: (postId: FormattedPost?, isActive: Bool) = (nil, false)
    
    func getPosts(latitude: Double, longitude: Double, token: String) async {
        if !initialPostsFetched { isLoading = true }
        defer { isLoading = false }
        let result = await AYServices.shared.getAllPublicationsNearBy(latitude: latitude, longitude: longitude, token: token)
        handleGetPostsResult(result)
    }
    
    private func handleGetPostsResult(_ result: Result<[FormattedPost], RequestError>) {
        switch result {
        case .success(let posts):
            updatePosts(with: posts)
            initialPostsFetched = true
        case .failure:
            overlayError = (true, ErrorMessage.getPostsErrorMessage)
        }
    }
    
    private func updatePosts(with posts: [FormattedPost]) {
        if shouldUpdateFeed {
            self.posts = posts
        }
    }
    
    func deletePost(postId: String, token: String) async {
        isLoading = true
        defer { isLoading = false }
        let result = await AYServices.shared.deletePublication(publicationId: postId, token: token)
        handlePostDeletionResult(withId: postId, result)
    }
    
    private func handlePostDeletionResult(withId postId: String, _ result: Result<DeletePublicationResponse, RequestError>) {
        switch result {
        case .success:
            posts.removeAll { $0.id == postId }
        case .failure:
            overlayError = (true, ErrorMessage.deletePostErrorMessage)
        }
    }
}
