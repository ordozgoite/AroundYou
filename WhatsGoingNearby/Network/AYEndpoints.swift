//
//  AYEndpoints.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 14/02/24.
//

import Foundation

enum AYEndpoints {
    case postNewUser(username: String, name: String?, userRegistrationToken: String, token: String)
    case postNewPublication(text: String, tag: String, postDuration: Int, latitude: Double, longitude: Double, isLocationVisible: Bool, token: String)
    case getActivePublicationsNearBy(latitude: Double, longitude: Double, token: String)
    case getUserInfo(userRegistrationToken: String?, preferredLanguage: String?, token: String)
    case likePublication(publicationId: String, latitude: Double, longitude: Double, token: String)
    case unlikePublication(publicationId: String, latitude: Double, longitude: Double, token: String)
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
    case postNewMessage(chatId: String, text: String, token: String)
    case getMessages(chatId: String, token: String)
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
            return "/api/Message/PostNewMessage"
        case .getMessages(let chatId, _):
            return "/api/Message/GetMessages/\(chatId)"
        }
    }
    
    //MARK: - Method
    
    var method: RequestMethod {
        switch self {
        case .postNewPublication, .postNewUser, .likePublication, .unlikePublication, .postNewComment, .deleteComment, .deletePublication, .editProfile, .postNewReport, .postNewBugReport, .blockUser, .unblockUser, .likeComment, .unlikeComment, .deleteProfilePic, .subscribeUserToPublication, .unsubscribeUser, .deleteNotification, .deleteUser, .postNewChat, .muteChat, .unmuteChat, .postNewMessage:
            return .post
        case .getActivePublicationsNearBy, .getUserInfo, .getAllCommentsByPublication, .getUserProfile, .getAllPublicationsByUser, .getBlockedUsers, .checkNearByPublications, .getPublicationLikes, .getCommentLikes, .getPublication, .getUserNotifications, .getUserBanExpireDate, .getAllPublicationsNearBy, .getChatsByUser, .getMessages:
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
        case .likePublication(let publicationId, let latitude, let longitude, _):
            let params: [String: Any] = [
                "publicationId": publicationId,
                "latitude": latitude,
                "longitude": longitude
            ]
            return params
        case .unlikePublication(let publicationId, let latitude, let longitude, _):
            let params: [String: Any] = [
                "publicationId": publicationId,
                "latitude": latitude,
                "longitude": longitude
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
        default:
            return nil
        }
    }
    
    //MARK: - Header
    
    var header: [String : String]? {
        switch self {
        case .postNewPublication(_, _, _, _, _, _, let token), .getActivePublicationsNearBy(_, _, let token), .postNewUser(_, _, _, let token), .getUserInfo(_, _, let token), .likePublication(_, _, _, let token), .unlikePublication(_, _, _, let token), .getAllCommentsByPublication(_, let token), .postNewComment(_, _, _, let token), .deleteComment(_, let token), .deletePublication(_, let token), .getUserProfile(_, let token), .editProfile(_, let token), .getAllPublicationsByUser(let token), .postNewReport(_, let token), .postNewBugReport(_, let token), .blockUser(_, let token), .getBlockedUsers(let token), .unblockUser(_, let token), .likeComment(_, _, _, let token), .unlikeComment(_, _, _, let token), .getPublicationLikes(_, let token), .getCommentLikes(_, let token), .deleteProfilePic(let token), .getPublication(_, _, _, let token), .getUserNotifications(let token), .subscribeUserToPublication(_, let token), .unsubscribeUser(_, let token), .deleteNotification(_, let token), .deleteUser(let token), .getUserBanExpireDate(let token), .getAllPublicationsNearBy(_, _, let token), .postNewChat(_, let token), .getChatsByUser(let token), .muteChat(_, let token), .unmuteChat(_, let token), .postNewMessage(_, _, let token), .getMessages(_, let token):
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
        case .postNewPublication(let text, let tag, let postDuration, let latitude, let longitude, let isLocationVisible, _):
            let params: [String: Any] = [
                "text": text,
                "tag": tag,
                "postDuration": postDuration,
                "latitude": latitude,
                "longitude": longitude,
                "isLocationVisible": isLocationVisible
            ]
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
        case .postNewMessage(let chatId, let text, _):
            let params: [String: Any] = [
                "chatId": chatId,
                "text": text
            ]
            return params
        case .getActivePublicationsNearBy, .getUserInfo, .likePublication, .unlikePublication, .getAllCommentsByPublication, .deleteComment, .deletePublication, .getUserProfile, .getAllPublicationsByUser, .getBlockedUsers, .likeComment, .unlikeComment, .checkNearByPublications, .getPublicationLikes, .getCommentLikes, .deleteProfilePic, .getPublication, .getUserNotifications, .subscribeUserToPublication, .unsubscribeUser, .deleteNotification, .deleteUser, .getUserBanExpireDate, .getAllPublicationsNearBy, .getChatsByUser, .muteChat, .unmuteChat, .getMessages:
            return nil
        }
    }
}
