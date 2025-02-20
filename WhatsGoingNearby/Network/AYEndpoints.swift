//
//  AYEndpoints.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 14/02/24.
//

import Foundation

enum AYEndpoints {
    case postNewUser(username: String, name: String?, userRegistrationToken: String, token: String)
    case postNewPublication(text: String?, tag: String, imageUrl: String?, postDuration: Int, latitude: Double, longitude: Double, isLocationVisible: Bool, token: String)
    case getActivePublicationsNearBy(latitude: Double, longitude: Double, token: String)
    case getUserInfo(userRegistrationToken: String?, preferredLanguage: String?, token: String)
    case likePublication(publicationId: String, token: String)
    case unlikePublication(publicationId: String, token: String)
    case getAllCommentsByPublication(publicationId: String, token: String)
    case postNewComment(comment: CommentDTO, latitude: Double, longitude: Double, token: String)
    case deleteComment(commentId: String, token: String)
    case deletePublication(publicationId: String, token: String)
    case getUserProfile(userUid: String, token: String)
    case editProfile(profile: UserProfileDTO, token: String)
    case getAllPublicationsByUser(token: String)
    case postNewReport(report: ReportDTO, token: String)
    case postNewBugReport(bugDescription: String, token: String)
    case blockUser(blockedUserUid: String, token: String)
    case getBlockedUsers(token: String)
    case unblockUser(blockedUserUid: String, token: String)
    case likeComment(commentId: String, latitude: Double, longitude: Double, token: String)
    case unlikeComment(commentId: String, latitude: Double, longitude: Double, token: String)
    case checkNearByPublications(userUid: String, latitude: Double, longitude: Double)
    case getPublicationLikes(publicationId: String, token: String)
    case getCommentLikes(commentId: String, token: String)
    case deleteProfilePic(token: String)
    case getPublication(publicationId: String, latitude: Double, longitude: Double, token: String)
    case getUserNotifications(token: String)
    case subscribeUserToPublication(publicationId: String, token: String)
    case unsubscribeUser(publicationId: String, token: String)
    case deleteNotification(notificationId: String, token: String)
    case deleteUser(token: String)
    case getUserBanExpireDate(token: String)
    case getAllPublicationsNearBy(latitude: Double, longitude: Double, token: String)
    case postNewChat(otherUserUid: String, token: String)
    case getChatsByUser(token: String)
    case muteChat(chatId: String, token: String)
    case unmuteChat(chatId: String, token: String)
    case postNewMessage(chatId: String, text: String?, imageUrl: String?, repliedMessageId: String?, token: String)
    case getMessages(chatId: String, timestamp: Int?, token: String)
    case deleteMessage(messageId: String, token: String)
    case editPublication(publicationId: String, text: String?, tag: String, postDuration: Int, isLocationVisible: Bool, latitude: Double, longitude: Double, token: String)
    case finishPublication(publicationId: String, token: String)
    case deleteChat(chatId: String, token: String)
    case getUnreadChatsNumber(token: String)
    case verifyUserDiscoverability(token: String)
    case activateUserDiscoverability(token: String)
    case updateUserPreferences(gender: String, interestGenders: [String], age: Int, minInterestAge: Int, maxInterestAge: Int, isNotificationsEnabled: Bool, token: String)
    case deactivateUserDiscoverability(token: String)
    case discoverUsersByPreferences(latitude: Double, longitude: Double, token: String)
    case postNewCommunity(name: String, description: String?, duration: Int, isLocationVisible: Bool, isPrivate: Bool, imageUrl: String?, latitude: Double, longitude: Double, token: String)
    case getCommunitiesNearBy(latitude: Double, longitude: Double, token: String)
    case joinCommunity(communityId: String, latitude: Double, longitude: Double, token: String)
    case askToJoinCommunity(communityId: String, latitude: Double, longitude: Double, token: String)
    case getCommunityInfo(communityId: String, token: String)
    case approveUserToCommunity(communityId: String, requestUserUid: String, token: String)
    case deleteCommunity(communityId: String, token: String)
    case exitCommunity(communityId: String, token: String)
    case removeUserFromCommunity(communityId: String, userUidToRemove: String, token: String)
    case editCommunity(communityId: String, communityName: String, communityImageUrl: String?, token: String)
    case editCommunityDescription(communityId: String, description: String?, token: String)
}

extension AYEndpoints: Endpoint {
    
    //MARK: - URL
    
    var path: String {
        switch self{
        case .postNewPublication:
            return "/api/Publication/PostNewPublication"
        case .getActivePublicationsNearBy:
            return "/api/Publication/GetActivePublicationsNearBy"
        case .postNewUser:
            return "/api/User/PostNewUser"
        case .getUserInfo:
            return "/api/User/GetUserInfo"
        case .likePublication:
            return "/api/Publication/LikePublication"
        case .unlikePublication:
            return "/api/Publication/UnlikePublication"
        case .getAllCommentsByPublication(let publicationId, _):
            return "/api/Comment/GetAllCommentsByPublication/\(publicationId)"
        case .postNewComment:
            return "/api/Comment/PostNewComment"
        case .deleteComment(let commentId, _):
            return "/api/Comment/DeleteComment/\(commentId)"
        case .deletePublication(let publicationId, _):
            return "/api/Publication/DeletePublication/\(publicationId)"
        case .getUserProfile(let userUid, _):
            return "/api/User/GetUserProfile/\(userUid)"
        case .editProfile:
            return "/api/User/EditProfile"
        case .getAllPublicationsByUser:
            return "/api/Publication/GetAllPublicationsByUser"
        case .postNewReport:
            return "/api/Report/PostNewReport"
        case .postNewBugReport:
            return "/api/BugReport/PostNewBugReport"
        case .blockUser:
            return "/api/Block/BlockUser"
        case .getBlockedUsers:
            return "/api/Block/GetBlockedUsers"
        case .unblockUser:
            return "/api/Block/UnblockUser"
        case .likeComment:
            return "/api/Comment/LikeComment"
        case .unlikeComment:
            return "/api/Comment/UnlikeComment"
        case .checkNearByPublications:
            return "/api/Publication/CheckNearByPublications"
        case .getPublicationLikes(let publicationId, _):
            return "/api/Publication/GetPublicationLikes/\(publicationId)"
        case .getCommentLikes(let commentId, _):
            return "/api/Comment/GetCommentLikes/\(commentId)"
        case .deleteProfilePic:
            return "/api/User/DeleteProfilePic"
        case .getPublication:
            return "/api/Publication/GetPublication"
        case .getUserNotifications:
            return "/api/Notification/GetUserNotifications"
        case .subscribeUserToPublication(let publicationId, _):
            return "/api/Subscription/SubscribeUserToPublication/\(publicationId)"
        case .unsubscribeUser(let publicationId, _):
            return "/api/Subscription/UnsubscribeUser/\(publicationId)"
        case .deleteNotification(let notificationId, _):
            return "/api/Notification/DeleteNotification/\(notificationId)"
        case .deleteUser:
            return "/api/User/DeleteUser"
        case .getUserBanExpireDate:
            return "/api/Ban/GetUserBanExpireDate"
        case .getAllPublicationsNearBy:
            return "/api/Publication/GetAllPublicationsNearBy"
        case .postNewChat:
            return "/api/Chat/PostNewChat"
        case .getChatsByUser:
            return "/api/Chat/GetChatsByUser"
        case .muteChat(let chatId, _):
            return "/api/Chat/MuteChat/\(chatId)"
        case .unmuteChat(let chatId, _):
            return "/api/Chat/UnmuteChat/\(chatId)"
        case .postNewMessage:
            return "/api/Message/PostMessage"
        case .getMessages:
            return "/api/Message/GetMessages"
        case .deleteMessage(let messageId, _):
            return "/api/Message/DeleteMessage/\(messageId)"
        case .editPublication:
            return "api/Publication/EditPublication"
        case .finishPublication(let publicationId, _):
            return "/api/Publication/FinishPublication/\(publicationId)"
        case .deleteChat(let chatId, _):
            return "/api/Chat/DeleteChat/\(chatId)"
        case .getUnreadChatsNumber:
            return "/api/Chat/GetUnreadChatsNumber"
        case .verifyUserDiscoverability:
            return "/api/Discovery/VerifyUserDiscoverability"
        case .activateUserDiscoverability:
            return "/api/Discovery/ActivateUserDiscoverability"
        case .updateUserPreferences:
            return "/api/Discovery/UpdateUserPreferences"
        case .deactivateUserDiscoverability:
            return "/api/Discovery/DeactivateUserDiscoverability"
        case .discoverUsersByPreferences:
            return "/api/Discovery/DiscoverUsersByPreferences"
        case .postNewCommunity:
            return "/api/Community/PostNewCommunity"
        case .getCommunitiesNearBy:
            return "/api/Community/GetCommunitiesNearBy"
        case .joinCommunity:
            return "/api/Community/JoinCommunity"
        case .askToJoinCommunity:
            return "/api/Community/AskToJoinCommunity"
        case .getCommunityInfo(let communityId, _):
            return "/api/Community/GetCommunityInfo/\(communityId)"
        case .approveUserToCommunity:
            return "/api/Community/ApproveUserToCommunity"
        case .deleteCommunity(let communityId, _):
            return "/api/Community/DeleteCommunity/\(communityId)"
        case .exitCommunity(let communityId, _):
            return "/api/Community/ExitCommunity/\(communityId)"
        case .removeUserFromCommunity:
            return "/api/Community/RemoveUserFromCommunity"
        case .editCommunity:
            return "/api/Community/EditCommunity"
        case .editCommunityDescription:
            return "/api/Community/EditCommunityDescription"
        }
    }
    
    //MARK: - Method
    
    var method: RequestMethod {
        switch self {
        case .postNewPublication, .postNewUser, .likePublication, .unlikePublication, .postNewComment, .deleteComment, .deletePublication, .editProfile, .postNewReport, .postNewBugReport, .blockUser, .unblockUser, .likeComment, .unlikeComment, .deleteProfilePic, .subscribeUserToPublication, .unsubscribeUser, .deleteNotification, .deleteUser, .postNewChat, .muteChat, .unmuteChat, .postNewMessage, .deleteMessage, .editPublication, .finishPublication, .deleteChat,.activateUserDiscoverability, .updateUserPreferences, .deactivateUserDiscoverability, .postNewCommunity, .joinCommunity, .askToJoinCommunity, .approveUserToCommunity, .deleteCommunity, .exitCommunity, .removeUserFromCommunity, .editCommunity, .editCommunityDescription:
            return .post
        case .getActivePublicationsNearBy, .getUserInfo, .getAllCommentsByPublication, .getUserProfile, .getAllPublicationsByUser, .getBlockedUsers, .checkNearByPublications, .getPublicationLikes, .getCommentLikes, .getPublication, .getUserNotifications, .getUserBanExpireDate, .getAllPublicationsNearBy, .getChatsByUser, .getMessages, .getUnreadChatsNumber, .verifyUserDiscoverability, .discoverUsersByPreferences, .getCommunitiesNearBy, .getCommunityInfo:
            return .get
        }
    }
    
    //MARK: - Query
    
    var query: [String: Any]? {
        switch self {
        case .getActivePublicationsNearBy(let latitude, let longitude, _):
            let params: [String: Any] = [
                "latitude": latitude,
                "longitude": longitude
            ]
            return params
        case .getAllPublicationsNearBy(let latitude, let longitude, _):
            let params: [String: Any] = [
                "latitude": latitude,
                "longitude": longitude
            ]
            return params
        case .checkNearByPublications(let userUid, let latitude, let longitude):
            let params: [String: Any] = [
                "userUid": userUid,
                "latitude": latitude,
                "longitude": longitude
            ]
            return params
        case .getUserInfo(let userRegistrationToken, let preferredLanguage, _):
            if let token = userRegistrationToken {
                var params: [String: Any] = [
                    "userRegistrationToken": token
                ]
                if let preferredLanguage = preferredLanguage { params["preferredLanguage"] = preferredLanguage }
                return params
            } else {
                return nil
            }
        case .getPublication(let publicationId, let latitude, let longitude, _):
            let params: [String: Any] = [
                "publicationId": publicationId,
                "latitude": latitude,
                "longitude": longitude
            ]
            return params
        case .likePublication(let publicationId, _):
            let params: [String: Any] = [
                "publicationId": publicationId
            ]
            return params
        case .unlikePublication(let publicationId, _):
            let params: [String: Any] = [
                "publicationId": publicationId
            ]
            return params
        case .likeComment(let commentId, let latitude, let longitude, _):
            let params: [String: Any] = [
                "commentId": commentId,
                "latitude": latitude,
                "longitude": longitude
            ]
            return params
        case .unlikeComment(let commentId, let latitude, let longitude, _):
            let params: [String: Any] = [
                "commentId": commentId,
                "latitude": latitude,
                "longitude": longitude
            ]
            return params
        case .getMessages(let chatId, let timestamp, _):
            var params: [String: Any] = [
                "chatId": chatId
            ]
            if let timestamp = timestamp { params["timestamp"] = timestamp }
            return params
        case .discoverUsersByPreferences(let latitude, let longitude, _):
            let params: [String: Any] = [
                "latitude": latitude,
                "longitude": longitude
            ]
            return params
        case .getCommunitiesNearBy(let latitude, let longitude, _):
            let params: [String: Any] = [
                "latitude": latitude,
                "longitude": longitude
            ]
            return params
        default:
            return nil
        }
    }
    
    //MARK: - Header
    
    var header: [String : String]? {
        switch self {
        case .postNewPublication(_, _, _, _, _, _, _, let token), .getActivePublicationsNearBy(_, _, let token), .postNewUser(_, _, _, let token), .getUserInfo(_, _, let token), .likePublication(_, let token), .unlikePublication(_, let token), .getAllCommentsByPublication(_, let token), .postNewComment(_, _, _, let token), .deleteComment(_, let token), .deletePublication(_, let token), .getUserProfile(_, let token), .editProfile(_, let token), .getAllPublicationsByUser(let token), .postNewReport(_, let token), .postNewBugReport(_, let token), .blockUser(_, let token), .getBlockedUsers(let token), .unblockUser(_, let token), .likeComment(_, _, _, let token), .unlikeComment(_, _, _, let token), .getPublicationLikes(_, let token), .getCommentLikes(_, let token), .deleteProfilePic(let token), .getPublication(_, _, _, let token), .getUserNotifications(let token), .subscribeUserToPublication(_, let token), .unsubscribeUser(_, let token), .deleteNotification(_, let token), .deleteUser(let token), .getUserBanExpireDate(let token), .getAllPublicationsNearBy(_, _, let token), .postNewChat(_, let token), .getChatsByUser(let token), .muteChat(_, let token), .unmuteChat(_, let token), .postNewMessage(_, _, _, _, let token), .getMessages(_, _, let token), .deleteMessage(_, let token), .editPublication(_, _, _, _, _, _, _, let token), .finishPublication(_, let token), .deleteChat(_, let token), .getUnreadChatsNumber(let token), .verifyUserDiscoverability(let token), .activateUserDiscoverability(let token), .updateUserPreferences(_, _, _, _, _, _, let token), .deactivateUserDiscoverability(let token),.discoverUsersByPreferences(_, _, let token), .postNewCommunity(_, _, _, _, _, _, _, _, let token), .getCommunitiesNearBy(_, _, let token), .joinCommunity(_, _, _, let token), .askToJoinCommunity(_, _, _, let token), .getCommunityInfo(_, let token), .approveUserToCommunity(_, _, let token), .deleteCommunity(_, let token), .exitCommunity(_, let token), .removeUserFromCommunity(_, _, let token), .editCommunity(_, _, _, let token), .editCommunityDescription(_, _, let token):
            return [
                "Authorization": "Bearer \(token)",
                "Accept": "application/x-www-form-urlencoded",
                "Content-Type": "application/json"
            ]
        default:
            return [
                "Accept": "application/x-www-form-urlencoded",
                "Content-Type": "application/json"
            ]
        }
    }
    
    //MARK: - Body
    
    var body: [String : Any]? {
        switch self {
        case .postNewPublication(let text, let tag, let imageUrl, let postDuration, let latitude, let longitude, let isLocationVisible, _):
            var params: [String: Any] = [
                "tag": tag,
                "postDuration": postDuration,
                "latitude": latitude,
                "longitude": longitude,
                "isLocationVisible": isLocationVisible
            ]
            if let text = text { params["text"] = text }
            if let url = imageUrl { params["imageUrl"] = url }
            return params
        case .postNewUser(let username, let name, let userRegistrationToken, _):
            var params: [String: Any] = [
                "username": username,
                "userRegistrationToken": userRegistrationToken
            ]
            if let name = name { params["name"] = name }
            return params
        case .postNewComment(let comment, let latitude, let longitude, _):
            var params: [String: Any] = [
                "publicationId": comment.publicationId,
                "text": comment.text,
                "latitude": latitude,
                "longitude": longitude
            ]
            if let repliedUserUid = comment.repliedUserUid { params["repliedUserUid"] = repliedUserUid }
            if let repliedUserUsername = comment.repliedUserUsername { params["repliedUserUsername"] = repliedUserUsername }
            return params
        case .editProfile(let profile, _):
            var params: [String: Any] = [:]
            if let username = profile.username { params["username"] = username }
            if let name = profile.name { params["name"] = name }
            if let biography = profile.biography { params["biography"] = biography }
            if let profilePic = profile.profilePic { params["profilePic"] = profilePic }
            return params
        case .postNewReport(let report, _):
            var params: [String: Any] = [
                "reportedUserUid": report.reportedUserUid
            ]
            if let publicationId = report.publicationId { params["publicationId"] = publicationId }
            if let commentId = report.commentId { params["commentId"] = commentId }
            if let reportDescription = report.reportDescription { params["reportDescription"] = reportDescription }
            return params
        case .postNewBugReport(let bugDescription, _):
            let params: [String: Any] = [
                "bugDescription": bugDescription
            ]
            return params
        case .blockUser(let blockedUserUid, _):
            let params: [String: Any] = [
                "blockedUserUid": blockedUserUid
            ]
            return params
        case .unblockUser(let blockedUserUid, _):
            let params: [String: Any] = [
                "blockedUserUid": blockedUserUid
            ]
            return params
        case .postNewChat(let otherUserUid, _):
            let params: [String: Any] = [
                "otherUserUid": otherUserUid
            ]
            return params
        case .postNewMessage(let chatId, let text, let imageUrl, let repliedMessageId, _):
            var params: [String: Any] = [
                "chatId": chatId
            ]
            if let id = repliedMessageId { params["repliedMessageId"] = id }
            if let text = text { params["text"] = text }
            if let imageUrl = imageUrl { params["imageUrl"] = imageUrl }
            return params
        case .editPublication(let publicationId, let text, let tag, let postDuration, let isLocationVisible, let latitude, let longitude, _):
            var  params: [String: Any] = [
                "publicationId": publicationId,
                "tag": tag,
                "postDuration": postDuration,
                "isLocationVisible": isLocationVisible,
                "latitude": latitude,
                "longitude": longitude
            ]
            if let text = text { params["text"] = text }
            return params
        case .updateUserPreferences(let gender, let interestGenders, let age, let minInterestAge, let maxInterestAge, let isNotificationsEnabled, _):
            let  params: [String: Any] = [
                "gender": gender,
                "interestGenders": interestGenders,
                "age": age,
                "minInterestAge": minInterestAge,
                "maxInterestAge": maxInterestAge,
                "isNotificationsEnabled": isNotificationsEnabled
            ]
            return params
        case .postNewCommunity(let name, let description, let duration, let isLocationVisible, let isPrivate, let imageUrl, let latitude, let longitude, _):
            var  params: [String: Any] = [
                "name": name,
                "duration": duration,
                "isLocationVisible": isLocationVisible,
                "latitude": latitude,
                "longitude": longitude,
                "isPrivate": isPrivate
            ]
            if let url = imageUrl { params["imageUrl"] = url }
            if let desc = description { params["description"] = desc }
            return params
        case .joinCommunity(let communityId, let latitude, let longitude, _):
            let params: [String: Any] = [
                "communityId": communityId,
                "latitude": latitude,
                "longitude": longitude
            ]
            return params
        case .askToJoinCommunity(let communityId, let latitude, let longitude, _):
            let params: [String: Any] = [
                "communityId": communityId,
                "latitude": latitude,
                "longitude": longitude
            ]
            return params
        case .approveUserToCommunity(let communityId, let requestUserUid, _):
            let params: [String: Any] = [
                "communityId": communityId,
                "requestUserUid": requestUserUid
            ]
            return params
        case .removeUserFromCommunity(let communityId, let userUidToRemove, _):
            let params: [String: Any] = [
                "communityId": communityId,
                "userUidToRemove": userUidToRemove
            ]
            return params
        case .editCommunity(let communityId, let communityName, let communityImageUrl, _):
            var params: [String: Any] = [
                "communityId": communityId,
                "communityName": communityName
            ]
            if let imageUrl = communityImageUrl { params["communityImageUrl"] = imageUrl }
            return params
        case .editCommunityDescription(let communityId, let description, _):
            var params: [String: Any] = [
                "communityId": communityId
            ]
            if let description = description { params["description"] = description }
            return params
        case .getActivePublicationsNearBy, .getUserInfo, .likePublication, .unlikePublication, .getAllCommentsByPublication, .deleteComment, .deletePublication, .getUserProfile, .getAllPublicationsByUser, .getBlockedUsers, .likeComment, .unlikeComment, .checkNearByPublications, .getPublicationLikes, .getCommentLikes, .deleteProfilePic, .getPublication, .getUserNotifications, .subscribeUserToPublication, .unsubscribeUser, .deleteNotification, .deleteUser, .getUserBanExpireDate, .getAllPublicationsNearBy, .getChatsByUser, .muteChat, .unmuteChat, .getMessages, .deleteMessage, .finishPublication, .deleteChat, .getUnreadChatsNumber, .verifyUserDiscoverability, .activateUserDiscoverability, .deactivateUserDiscoverability,.discoverUsersByPreferences, .getCommunitiesNearBy, .getCommunityInfo, .deleteCommunity, .exitCommunity:
            return nil
        }
    }
}
