//
//  AYEndpoints.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 14/02/24.
//

import Foundation

enum AYEndpoints {
    case postNewUser(name: String, userRegistrationToken: String, token: String)
    case postNewPublication(text: String, latitude: Double, longitude: Double, isLocationVisible: Bool, token: String)
    case getActivePublicationsNearBy(latitude: Double, longitude: Double, token: String)
    case getUserInfo(userRegistrationToken: String?, token: String)
    case likePublication(publicationId: String, token: String)
    case unlikePublication(publicationId: String, token: String)
    case getAllCommentsByPublication(publicationId: String, token: String)
    case postNewComment(publicationId: String, text: String, token: String)
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
    case likeComment(commentId: String, token: String)
    case unlikeComment(commentId: String, token: String)
    case checkNearByPublications(userUid: String, latitude: Double, longitude: Double)
    case getPublicationLikes(publicationId: String, token: String)
    case getCommentLikes(commentId: String, token: String)
    case deleteProfilePic(token: String)
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
        case .likePublication(let publicationId, _):
            return "/api/Publication/LikePublication/\(publicationId)"
        case .unlikePublication(let publicationId, _):
            return "/api/Publication/UnlikePublication/\(publicationId)"
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
        case .likeComment(let commentId, _):
            return "/api/Comment/LikeComment/\(commentId)"
        case .unlikeComment(let commentId, _):
            return "/api/Comment/UnlikeComment/\(commentId)"
        case .checkNearByPublications:
            return "/api/Publication/CheckNearByPublications"
        case .getPublicationLikes(let publicationId, _):
            return "/api/Publication/GetPublicationLikes/\(publicationId)"
        case .getCommentLikes(let commentId, _):
            return "/api/Comment/GetCommentLikes/\(commentId)"
        case .deleteProfilePic:
            return "/api/User/DeleteProfilePic"
        }
    }
    
    //MARK: - Method
    
    var method: RequestMethod {
        switch self {
        case .postNewPublication, .postNewUser, .likePublication, .unlikePublication, .postNewComment, .deleteComment, .deletePublication, .editProfile, .postNewReport, .postNewBugReport, .blockUser, .unblockUser, .likeComment, .unlikeComment, .deleteProfilePic:
            return .post
        case .getActivePublicationsNearBy, .getUserInfo, .getAllCommentsByPublication, .getUserProfile, .getAllPublicationsByUser, .getBlockedUsers, .checkNearByPublications, .getPublicationLikes, .getCommentLikes:
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
        case .checkNearByPublications(let userUid, let latitude, let longitude):
            let params: [String: Any] = [
                "userUid": userUid,
                "latitude": latitude,
                "longitude": longitude
            ]
            return params
        case .getUserInfo(let userRegistrationToken, _):
            if let token = userRegistrationToken {
                let params: [String: Any] = [
                    "userRegistrationToken": token
                ]
                return params
            } else {
                return nil
            }
        default:
            return nil
        }
    }
    
    //MARK: - Header
    
    var header: [String : String]? {
        switch self {
        case .postNewPublication(_, _, _, _, let token):
            return [
                "Authorization": "Bearer \(token)",
                "Accept": "application/x-www-form-urlencoded",
                "Content-Type": "application/json"
            ]
        case .getActivePublicationsNearBy(_, _, let token):
            return [
                "Authorization": "Bearer \(token)",
                "Accept": "application/x-www-form-urlencoded",
                "Content-Type": "application/json"
            ]
        case .postNewUser(_, _, let token):
            return [
                "Authorization": "Bearer \(token)",
                "Accept": "application/x-www-form-urlencoded",
                "Content-Type": "application/json"
            ]
        case .getUserInfo(_, let token):
            return [
                "Authorization": "Bearer \(token)",
                "Accept": "application/x-www-form-urlencoded",
                "Content-Type": "application/json"
            ]
        case .likePublication(_, let token):
            return [
                "Authorization": "Bearer \(token)",
                "Accept": "application/x-www-form-urlencoded",
                "Content-Type": "application/json"
            ]
        case .unlikePublication(_, let token):
            return [
                "Authorization": "Bearer \(token)",
                "Accept": "application/x-www-form-urlencoded",
                "Content-Type": "application/json"
            ]
        case .getAllCommentsByPublication(_, let token):
            return [
                "Authorization": "Bearer \(token)",
                "Accept": "application/x-www-form-urlencoded",
                "Content-Type": "application/json"
            ]
        case.postNewComment(_, _, let token):
            return [
                "Authorization": "Bearer \(token)",
                "Accept": "application/x-www-form-urlencoded",
                "Content-Type": "application/json"
            ]
        case .deleteComment(_, let token):
            return [
                "Authorization": "Bearer \(token)",
                "Accept": "application/x-www-form-urlencoded",
                "Content-Type": "application/json"
            ]
        case .deletePublication(_, let token):
            return [
                "Authorization": "Bearer \(token)",
                "Accept": "application/x-www-form-urlencoded",
                "Content-Type": "application/json"
            ]
        case .getUserProfile(_, let token):
            return [
                "Authorization": "Bearer \(token)",
                "Accept": "application/x-www-form-urlencoded",
                "Content-Type": "application/json"
            ]
        case .editProfile(_, let token):
            return [
                "Authorization": "Bearer \(token)",
                "Accept": "application/x-www-form-urlencoded",
                "Content-Type": "application/json"
            ]
        case .getAllPublicationsByUser(let token):
            return [
                "Authorization": "Bearer \(token)",
                "Accept": "application/x-www-form-urlencoded",
                "Content-Type": "application/json"
            ]
        case .postNewReport(_, let token):
            return [
                "Authorization": "Bearer \(token)",
                "Accept": "application/x-www-form-urlencoded",
                "Content-Type": "application/json"
            ]
        case .postNewBugReport(_, let token):
            return [
                "Authorization": "Bearer \(token)",
                "Accept": "application/x-www-form-urlencoded",
                "Content-Type": "application/json"
            ]
        case .blockUser(_, let token):
            return [
                "Authorization": "Bearer \(token)",
                "Accept": "application/x-www-form-urlencoded",
                "Content-Type": "application/json"
            ]
        case .getBlockedUsers(let token):
            return [
                "Authorization": "Bearer \(token)",
                "Accept": "application/x-www-form-urlencoded",
                "Content-Type": "application/json"
            ]
        case .unblockUser(_, let token):
            return [
                "Authorization": "Bearer \(token)",
                "Accept": "application/x-www-form-urlencoded",
                "Content-Type": "application/json"
            ]
        case .likeComment(_, let token):
            return [
                "Authorization": "Bearer \(token)",
                "Accept": "application/x-www-form-urlencoded",
                "Content-Type": "application/json"
            ]
        case .unlikeComment(_, let token):
            return [
                "Authorization": "Bearer \(token)",
                "Accept": "application/x-www-form-urlencoded",
                "Content-Type": "application/json"
            ]
        case .getPublicationLikes(_, let token):
            return [
                "Authorization": "Bearer \(token)",
                "Accept": "application/x-www-form-urlencoded",
                "Content-Type": "application/json"
            ]
        case .getCommentLikes(_, let token):
            return [
                "Authorization": "Bearer \(token)",
                "Accept": "application/x-www-form-urlencoded",
                "Content-Type": "application/json"
            ]
        case .deleteProfilePic(let token):
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
        case .postNewPublication(let text, let latitude, let longitude, let isLocationVisible, _):
            let params: [String: Any] = [
                "text": text,
                "latitude": latitude,
                "longitude": longitude,
                "isLocationVisible": isLocationVisible
            ]
            return params
        case .postNewUser(let name, let userRegistrationToken, _):
            let params: [String: Any] = [
                "name": name,
                "userRegistrationToken": userRegistrationToken
            ]
            return params
        case .postNewComment(let publicationId, let text, _):
            let params: [String: Any] = [
                "publicationId": publicationId,
                "text": text
            ]
            return params
        case .editProfile(let profile, _):
            var params: [String: Any] = [:]
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
        case .getActivePublicationsNearBy, .getUserInfo, .likePublication, .unlikePublication, .getAllCommentsByPublication, .deleteComment, .deletePublication, .getUserProfile, .getAllPublicationsByUser, .getBlockedUsers, .likeComment, .unlikeComment, .checkNearByPublications, .getPublicationLikes, .getCommentLikes, .deleteProfilePic:
            return nil
        }
    }
}
