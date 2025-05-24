//
//  CommunityDetailViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 19/02/25.
//

import Foundation
import SwiftUI
import PhotosUI

@MainActor
class CommunityDetailViewModel: ObservableObject {
    
    @Published var members: [MongoUser] = []
    @Published var joinRequests: [MongoUser]?
    @Published var communityOwnerUid: String = ""
    @Published var isCommunityPrivate: Bool = false
    @Published var overlayError: (Bool, LocalizedStringKey) = (false, "")
    @Published var hasFetchedCommunityInfo: Bool = false
    @Published var isEditDescriptionViewDisplayed: Bool = false
    @Published var isEditCommunityViewDisplayed: Bool = false
    
    // Loading
    @Published var isApprovingUserToCommunity: (Bool, String) = (false, "")
    @Published var isLeavingCommunity: Bool = false
    @Published var isDeletingCommunity: Bool = false
    @Published var isEditingDescription: Bool = false
    
    // Edit Community
    @Published var communityNameInput: String = ""
    @Published var isImageOptionsDisplayed: Bool = false
    @Published var imageSelection: PhotosPickerItem?
    @Published var isCropViewDisplayed: Bool = false
    @Published var image: UIImage?
    @Published var croppedImage: UIImage?
    @Published var isPhotoPickerPresented: Bool = false
    @Published var isEditingCommunity: Bool = false
    @Published var communityImageDisplaySource: ImageDisplaySource = .none
    var newImageUrl: String?
    
    func getCommunityInfo(communityId: String, token: String) async {
        let result = await AYServices.shared.getCommunityInfo(communityId: communityId, token: token)
        
        switch result {
        case .success(let communityInfo):
            setCommunityInfo(communityInfo)
            hasFetchedCommunityInfo = true
        case .failure:
            overlayError = (true, ErrorMessage.getCommunityInfo)
        }
    }
    
    private func setCommunityInfo(_ communityInfo: GetCommunityInfoResponse) {
        self.members = communityInfo.members
        self.joinRequests = communityInfo.joinRequests
        self.communityOwnerUid = communityInfo.ownerUid
    }
    
    func approveUserToCommunity(communityId: String, requestUser: MongoUser, token: String) async {
        isApprovingUserToCommunity = (true, requestUser.userUid)
        let result = await AYServices.shared.approveUserToCommunity(communityId: communityId, requestUserUid: requestUser.userUid, token: token)
        isApprovingUserToCommunity = (false, "")
        
        switch result {
        case .success:
            removeFromJoinRequests(requestUser.userUid)
            addToMembers(requestUser)
        case .failure:
            overlayError = (true, ErrorMessage.approveUserToCommunity)
        }
    }
    
    private func removeFromJoinRequests(_ userUid: String) {
        guard var requests = joinRequests else { return }
        requests.removeAll { $0.userUid == userUid }
        joinRequests = requests
    }

    
    private func addToMembers(_ user: MongoUser) {
        self.members.append(user)
    }
    
    func removeMember(communityId: String, userUidToRemove: String, token: String) async {
        let result = await AYServices.shared.removeUserFromCommunity(communityId: communityId, userUidToRemove: userUidToRemove, token: token)
        
        switch result {
        case .success:
            removeFromMembers(userUidToRemove)
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
    }
    
    private func removeFromMembers(_ userUid: String) {
        members.removeAll { $0.userUid == userUid }
    }
    
    func leaveCommunity(communityId: String, token: String) async throws {
        isLeavingCommunity = true
        let result = await AYServices.shared.exitCommunity(communityId: communityId, token: token)
        isLeavingCommunity = false
        
        switch result {
        case .success:
            print("✅ Success!")
        case .failure:
            overlayError = (true, ErrorMessage.leaveCommunity)
            throw NSError(domain: "LeaveCommunityError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to leave community"])
        }
    }
    
    func deleteCommunity(communityId: String, token: String) async throws {
        isDeletingCommunity = true
        let result = await AYServices.shared.deleteCommunity(communityId: communityId, token: token)
        isDeletingCommunity = false
        
        switch result {
        case .success:
            print("✅ Success!")
        case .failure:
            overlayError = (true, ErrorMessage.deleteCommunity)
            throw NSError(domain: "DeleteCommunityError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to delete community"])
        }
    }
    
    func editCommunityDescription(communityId: String, newDescription: String?, token: String) async throws {
        isEditingDescription = true
        let result = await AYServices.shared.editCommunityDescription(communityId: communityId, description: newDescription, token: token)
        isEditingDescription = false
        
        switch result {
        case .success:
            print("✅ Success!")
        case .failure:
            overlayError = (true, ErrorMessage.editCommunityDescription)
            throw NSError(domain: "EditCommunityDescriptionError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to edit community description"])
        }
    }
    
    func editCommunity(communityId: String, prevImageUrl: String?, token: String) async throws {
        isEditingCommunity = true
        newImageUrl = await determineNewImageUrl(previousUrl: prevImageUrl)
        let result = await AYServices.shared.editCommunity(communityId: communityId, communityName: communityNameInput, communityImageUrl: self.newImageUrl, token: token)
        isEditingCommunity = false
        
        switch result {
        case .success:
            print("✅ Success!")
        case .failure:
            overlayError = (true, ErrorMessage.editCommunity)
            throw NSError(domain: "EditCommunityError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to edit community"])
        }
    }
    
    func updateCommunityPrivacy(withId communityId: String, token: String) async {
        let newPrivacyStatus = self.isCommunityPrivate
        let result = await AYServices.shared.updateCommunityPrivacy(communityId: communityId, isPrivate: newPrivacyStatus, token: token)
        
        switch result {
        case .success:
            print("✅ Success!")
        case .failure:
            self.isCommunityPrivate = !newPrivacyStatus
            overlayError = (true, "Error trying to update community privacy")
        }
    }
    
    private func determineNewImageUrl(previousUrl: String?) async -> String? {
        guard isNewImageSelected() else { return previousUrl }
        return croppedImage == nil ? nil : await getImageUrl()
    }

    private func isNewImageSelected() -> Bool {
        return communityImageDisplaySource != .url
    }
    
    private func getImageUrl() async -> String? {
        do {
            return try await FirebaseService.shared.storeImageAndGetUrl(self.croppedImage!)
        } catch {
            overlayError = (true, ErrorMessage.postImageErrorMessage)
            return nil
        }
    }
}
