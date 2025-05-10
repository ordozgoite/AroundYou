//
//  ErrorMessage.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 15/02/24.
//

import Foundation
import SwiftUI

struct ErrorMessage {
    
    static let defaultErrorMessage: LocalizedStringKey = "Oops! Something went wrong. Please try again later."
    static let locationDisabledErrorMessage: LocalizedStringKey = "We couldn’t access your location. Please enable location permissions in your device settings."
    static let invalidUsernameMessage: LocalizedStringKey = "This username contains invalid characters. Please choose another one."
    static let usernameInUseMessage: LocalizedStringKey = "This username is already taken. Please try a different one."
    static let commentDistanceLimitExceededErrorMessage: LocalizedStringKey = "You're too far away to comment on this post."
    static let publicationLimitExceededErrorMessage: LocalizedStringKey = "You’ve reached the maximum number of active posts allowed."
    static let selectPhotoErrorMessage: LocalizedStringKey = "Failed to select a photo. Please try again."
    static let permaBannedErrorMessage: LocalizedStringKey = "Your account has been permanently banned."
    static let editDistanceLimitExceededErrorMessage: LocalizedStringKey = "You're too far away to edit this post."
    static let postImageErrorMessage: LocalizedStringKey = "Failed to upload image. Please try again."

    static func getTempBannedErrorMessage(expirationDate: Int) -> LocalizedStringKey {
        return "Your account has been temporarily banned until \(expirationDate.convertTimestampToDate().convertDateToString())."
    }

    static let postUserErrorMessage: LocalizedStringKey = "Failed to create user. Please try again."
    static let getUserInfoErrorMessage: LocalizedStringKey = "Failed to retrieve user information."
    static let getUserBanExpirarationDateErrorMessage: LocalizedStringKey = "Failed to retrieve ban expiration date."

    static let getPostsErrorMessage: LocalizedStringKey = "Failed to load nearby posts. Please try again."
    static let deletePostErrorMessage: LocalizedStringKey = "Failed to delete post. Please try again."

    static let postIncidentReportErrorMessage: LocalizedStringKey = "Failed to submit report. Please try again."
    static let getReportInfoErrorMessage: LocalizedStringKey = "Failed to load report details. Please try again."

    static let postLostItemErrorMessage: LocalizedStringKey = "Failed to post lost item. Please try again."
    static let getLostItemInfoErrorMessage: LocalizedStringKey = "Failed to load lost item details. Please try again."
    static let setItemAsFoundErrorMessage: LocalizedStringKey = "Failed to mark item as found. Please try again."

    static let createPostErrorMessage: LocalizedStringKey = "Failed to create post. Please try again later."
    static let editPostErrorMessage: LocalizedStringKey = "Failed to edit post. Please try again later."
    static let deletePost: LocalizedStringKey = "Failed to delete post. Please try again."
    static let getPostLikes: LocalizedStringKey = "Failed to load post likes. Please try again."
    static let getCommentLikes: LocalizedStringKey = "Failed to load comment likes. Please try again."

    static let getNotifications: LocalizedStringKey = "Failed to load notifications. Please try again."
    static let deleteNotifications: LocalizedStringKey = "Failed to delete notifications. Please try again."

    static let getAllComments: LocalizedStringKey = "Failed to load comments. Please try again."
    static let postComment: LocalizedStringKey = "Failed to post comment. Please try again."
    static let deleteComment: LocalizedStringKey = "Failed to delete comment. Please try again."

    static let getChats: LocalizedStringKey = "Failed to load chats. Please try again."
    static let deleteChat: LocalizedStringKey = "Failed to delete chat. Please try again."
    static let muteChat: LocalizedStringKey = "Failed to mute chat. Please try again."
    static let unmuteChat: LocalizedStringKey = "Failed to unmute chat. Please try again."
    static let postNewChat: LocalizedStringKey = "Failed to start new chat. Please try again."

    static let getMessages: LocalizedStringKey = "Failed to load messages. Please try again."
    static let sendMessage: LocalizedStringKey = "Failed to send message. Please try again."
    static let deleteMessage: LocalizedStringKey = "Failed to delete message. Please try again."

    static let verifyUserDiscoverability: LocalizedStringKey = "Failed to verify discoverability. Please try again."
    static let activateUserDiscoverability: LocalizedStringKey = "Failed to activate discoverability. Please try again."
    static let deactivateUserDiscoverability: LocalizedStringKey = "Failed to deactivate discoverability. Please try again."
    static let updateUserPreferences: LocalizedStringKey = "Failed to update preferences. Please try again."
    static let getUsersNearBy: LocalizedStringKey = "Failed to load nearby users. Please try again."

    static let getCommunitiesNearBy: LocalizedStringKey = "Failed to load nearby communities. Please try again."
    static let joinCommunity: LocalizedStringKey = "Failed to join community. Please try again."
    static let askToJoinCommunity: LocalizedStringKey = "Failed to request to join community. Please try again."
    static let postNewCommunity: LocalizedStringKey = "Failed to create community. Please try again."
    static let getCommunityInfo: LocalizedStringKey = "Failed to load community information. Please try again."
    static let approveUserToCommunity: LocalizedStringKey = "Failed to approve user. Please try again."
    static let leaveCommunity: LocalizedStringKey = "Failed to leave community. Please try again."
    static let deleteCommunity: LocalizedStringKey = "Failed to delete community. Please try again."
    static let editCommunityDescription: LocalizedStringKey = "Failed to edit community description. Please try again."
    static let editCommunity: LocalizedStringKey = "Failed to update community. Please try again."

    static let getBusinesses: LocalizedStringKey = "Failed to load nearby businesses. Please try again."
    static let getBusinessByUser: LocalizedStringKey = "Failed to load your businesses. Please try again."
    static let deleteBusiness: LocalizedStringKey = "Failed to delete business. Please try again."
    static let publishBusiness: LocalizedStringKey = "Failed to publish business. Please try again."
    static let businessesPublishedLimitExceeded: LocalizedStringKey = "You’ve reached the maximum number of businesses you can publish."

    static let getUserPosts: LocalizedStringKey = "Failed to load your posts. Please try again."
    static let getUserInfo: LocalizedStringKey = "Failed to load user information. Please try again."
    static let editProfile: LocalizedStringKey = "Failed to update profile. Please try again."
    static let removePhoto: LocalizedStringKey = "Failed to remove profile picture. Please try again."
    static let getUserProfile: LocalizedStringKey = "Failed to load user profile. Please try again."
    static let blockUser: LocalizedStringKey = "Failed to block user. Please try again."
    static let getBockedUsers: LocalizedStringKey = "Failed to load blocked users. Please try again."
    static let unblockUser: LocalizedStringKey = "Failed to unblock user. Please try again."

}
