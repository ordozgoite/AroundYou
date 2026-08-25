//
//  PostsClusterViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 12/05/26.
//

import Foundation
import SwiftUI

@MainActor
class ClusterPostsViewModel: ObservableObject {
    @Published var posts: [FormattedPost] = []
    @Published var isLoading: Bool = false
    @Published var hasFetched: Bool = false
    @Published var overlayError: (Bool, LocalizedStringKey) = (false, "")

    func fetchPosts(forBounds bounds: MapClusterBounds, withLocation location: Location, withToken token: String) async {
        let response = await AYServices.shared.getAllPublicationsInRegion(bounds: bounds, location: location, token: token)

        switch response {
        case .success(let posts):
            self.hasFetched = true
            self.posts = posts
        case .failure:
            overlayError = (true, ErrorMessage.getClusterPostsErrorMessage)
        }
    }
}
