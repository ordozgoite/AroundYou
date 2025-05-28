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
    @Published var navPath: [PostNavigation] = []
    
    func getUserPosts(location:  Location, token: String) async {
        let response = await AYServices.shared.getAllPublicationsByUser(latitude: location.latitude, longitude: location.longitude, token: token)
        
        switch response {
        case .success(let posts):
            self.posts = posts
        case .failure:
            overlayError = (true, ErrorMessage.getUserPosts)
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
}
