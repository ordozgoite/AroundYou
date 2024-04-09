//
//  FeedViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import Foundation
import SwiftUI

@MainActor
class FeedViewModel: ObservableObject {
    
    init() {
        addObservers()
    }
    
    @Published var posts: [FormattedPost] = []
    @Published var isLoading: Bool = false
    @Published var isCommentScreenPresented = false
    @Published var overlayError: (Bool, LocalizedStringKey) = (false, "")
    @Published var initialPostsFetched: Bool = false
    @Published var timer: Timer?
    @Published var feedTimer: Timer?
    @Published var currentTimeStamp: Int = Int(Date().timeIntervalSince1970)
    @Published var shouldUpdateFeed: Bool = true
    @Published var isTabBarDoubleClicked: Bool = false
    
    var groupedPosts: [(Date, [FormattedPost])] {
        let groupedDict = Dictionary(grouping: posts) { (post) -> Date in
            return Date(timeIntervalSince1970: TimeInterval(post.timestamp))
        }
        return groupedDict.sorted { $0.key > $1.key }
    }
    
    private func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(scrollToTop), name: Notification.Name(Constants.scrollToTopNotificationKey), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshFeed), name: Notification.Name(Constants.refreshFeedNotificationKey), object: nil)
    }
    
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
    
    @objc private func scrollToTop() {
        isTabBarDoubleClicked.toggle()
    }
    
    @objc private func refreshFeed() {
        posts = []
        initialPostsFetched = false
    }
}
