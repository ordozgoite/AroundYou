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
    @Published var didTriggerCreateForPending = false
    
    @Published var postToBePublished: PendingPost? = nil
    
    func getPosts(location: Location, token: String) async {
        if !initialPostsFetched { isLoading = true }
        defer { isLoading = false }
        let result = await AYServices.shared.getAllPublicationsNearBy(latitude: location.latitude, longitude: location.longitude, token: token)
        switch result {
        case .success(let posts):
            updatePosts(with: posts)
        case .failure:
            if !initialPostsFetched {
                overlayError = (true, ErrorMessage.getPostsErrorMessage)
            }
        }
        initialPostsFetched = true
    }
    
    func createNewPost(latitude: Double, longitude: Double, token: String) async throws {
        postToBePublished?.progress = 0.05
        postToBePublished?.status = .queued
        if let post = postToBePublished {
            var imageUrl: String? = nil
            if let img = post.image {
                postToBePublished?.progress = 0.2
                postToBePublished?.status = .uploadingImage
                imageUrl = await storeImage(image: img)
            }
            postToBePublished?.progress = 0.7
            postToBePublished?.status = .creatingPost
            let result = await AYServices.shared.postNewPublication(
                text: post.text.nonEmptyOrNil(),
                tag: post.tag.rawValue,
                imageUrl: imageUrl,
                latitude: latitude,
                longitude: longitude,
                isLocationVisible: post.isLocationVisible,
                token: token
            )
            didTriggerCreateForPending = false
            try handleCreateNewPostResult(result)
        }
    }
    
    private func handleCreateNewPostResult(_ result: Result<Post, RequestError>) throws {
        switch result {
        case .success:
            print("✅ Post successfully created.")
            postToBePublished?.progress = 1
            postToBePublished?.status = .completed
            refreshFeed()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.postToBePublished = nil
            }
        case .failure(let error):
            if error == .forbidden {
                overlayError = (true, ErrorMessage.publicationLimitExceededErrorMessage)
                postToBePublished?.progress = 0
                postToBePublished?.status = .failed(message: "Limite de publicação")
            } else {
                overlayError = (true, ErrorMessage.createPostErrorMessage)
                postToBePublished?.progress = 0
                postToBePublished?.status = .failed(message: "Erro ao publicar")
            }
            throw error
        }
    }
    
    private func refreshFeed() {
        NotificationCenter.default.post(name: .refreshLocationSensitiveData, object: nil)
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
            removePost(withId: postId)
        case .failure:
            overlayError = (true, ErrorMessage.deletePostErrorMessage)
        }
    }
    
    func removePost(withId postId: String) {
        posts.removeAll { $0.id == postId }
    }
    
    func likePost(withId postId: String) {
        if let index = posts.firstIndex(where: { $0.id == postId }),
           posts[index].likes != nil,
           posts[index].didLike != nil {
            posts[index].likes! += 1
            posts[index].didLike = true
        }
    }
    
    func unlikePost(withId postId: String) {
        if let index = posts.firstIndex(where: { $0.id == postId }),
           posts[index].likes != nil,
           posts[index].didLike != nil {
            posts[index].likes! -= 1
            posts[index].didLike = false
        }
    }
    
    func finishPost(withId postId: String) {
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            posts[index].isFinished = true
        }
    }
    
    func followPost(withId postId: String) {
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            posts[index].isSubscribed = true
        }
    }
    
    func unfollowPost(withId postId: String) {
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            posts[index].isSubscribed = false
        }
    }
    
    private func storeImage(image: UIImage) async -> String? {
        do {
            return try await FirebaseService.shared.storeImageAndGetUrl(image)
        } catch {
            overlayError = (true, ErrorMessage.postImageErrorMessage)
            isLoading = false
            return nil
        }
    }
}
