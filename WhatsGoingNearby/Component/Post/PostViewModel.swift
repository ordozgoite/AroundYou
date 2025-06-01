//
//  PostViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 19/04/25.
//

import Foundation
import SwiftUI

enum LostItemError: Error {
    case deletionFailed
}

enum IncidentReportError: Error {
    case deletionFailed
}

@MainActor
class PostViewModel: ObservableObject {
    @Published var isTimeLeftPopoverDisplayed: Bool = false
    @Published var isOptionsPopoverDisplayed: Bool = false
    @Published var isFullScreenImageDisplayed: Bool = false
//    @Published var didLikePost: Bool = false
//    @Published var postLikes: Int = 0
    
    func deletePost(postId: String, token: String) async throws {
        let result = await AYServices.shared.deletePublication(publicationId: postId, token: token)
        
        switch result {
        case .success:
            print("✅ Succesfully deleted post!")
        case .failure(let error):
            throw error
        }
    }
    
    func deleteLostItem(lostItemId: String, token: String) async throws {
        let result = await AYServices.shared.deleteLostItem(lostItemId: lostItemId, token: token)
        
        switch result {
        case .success:
            print("✅ Succesfully deleted lost item!")
        case .failure(let error):
            throw error
        }
    }
    
    func deleteReport(reportId: String, token: String) async throws {
        let result = await AYServices.shared.deleteReportIncident(reportId: reportId, token: token)
        
        switch result {
        case .success:
            print("✅ Succesfully deleted report!")
        case .failure(let error):
            throw error
        }
    }
    
    func getTimeLeftText(forPost post: FormattedPost) -> LocalizedStringKey {
        var timeLeft: Int
        var pluralModifier: String = ""
        
        let timeLeftInSeconds = post.expirationDate.timeIntervalSince1970InSeconds - getCurrentDateTimestamp()
        if timeLeftInSeconds < 60 {
            timeLeft = timeLeftInSeconds
            if timeLeft != 1 { pluralModifier = "s" }
            return LocalizedStringKey("\(timeLeft) second\(pluralModifier) to expire")
        } else if timeLeftInSeconds < 3600 {
            timeLeft = Int(timeLeftInSeconds / 60)
            if timeLeft != 1 { pluralModifier = "s" }
            return LocalizedStringKey("\(timeLeft) minute\(pluralModifier) to expire")
        } else {
            timeLeft = Int(timeLeftInSeconds / 3600)
            if timeLeft != 1 { pluralModifier = "s" }
            return LocalizedStringKey("\(timeLeft) hour\(pluralModifier) to expire")
        }
    }
    
    func followPost(postId: String, token: String) async throws {
        let result = await AYServices.shared.subscribeUserToPublication(publicationId: postId, token: token)
        
        switch result {
        case .success:
            print("✅ Succesfully followed post!")
        case .failure(let error):
            throw error
        }
    }
    
    func unfollowPost(postId: String, token: String) async throws {
        let result = await AYServices.shared.unsubscribeUser(publicationId: postId, token: token)
        
        switch result {
        case .success:
            print("✅ Succesfully unfollowed post!")
        case .failure(let error):
            throw error
        }
    }
    
    func likePublication(publicationId: String, token: String) async throws {
        let result = await AYServices.shared.likePublication(publicationId: publicationId, token: token)
        
        switch result {
        case .success:
            print("✅ Succesfully liked post!")
        case .failure(let error):
            throw error
        }
    }
    
    func unlikePublication(publicationId: String, token: String) async throws {
        let result = await AYServices.shared.unlikePublication(publicationId: publicationId, token: token)
        
        switch result {
        case .success:
            print("✅ Succesfully unliked post!")
        case .failure(let error):
            throw error
        }
    }
    
    func finishPublication(postId: String, token: String) async throws {
        let result = await AYServices.shared.finishPublication(publicationId: postId, token: token)
        
        switch result {
        case .success:
            print("✅ Publication successfully finished.")
        case .failure:
            // TODO: Throw Error
            print("❌ Error trying to Finish Publication.")
        }
    }
    
//    func refreshFeed() {
//        NotificationCenter.default.post(name: .refreshLocationSensitiveData, object: nil)
//    }
    
    func isActivePublication(_ post: FormattedPost) -> Bool {
        return post.status == .active && post.postSource == .publication
    }
    
//    private func updateUserProfilePosts() {
//        NotificationCenter.default.post(name: .updateUserProfilePosts, object: nil)
//    }
}
