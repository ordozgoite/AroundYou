//
//  AYEndpoints.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 14/02/24.
//

import Foundation

enum AYEndpoints {
    case postNewUser(name: String, token: String)
    case postNewPublication(text: String, latitude: Double, longitude: Double, token: String)
    case getActivePublicationsNearBy(latitude: Double, longitude: Double, token: String)
    case getUserInfo(token: String)
    case likePublication(publicationId: String, token: String)
    case unlikePublication(publicationId: String, token: String)
    case getAllCommentsByPublication(publicationId: String, token: String)
    case postNewComment(publicationId: String, text: String, token: String)
    case deleteComment(commentId: String, token: String)
    case deletePublication(publicationId: String, token: String)
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
        }
    }
    
    //MARK: - Method
    
    var method: RequestMethod {
        switch self {
        case .postNewPublication, .postNewUser, .likePublication, .unlikePublication, .postNewComment, .deleteComment, .deletePublication:
            return .post
        case .getActivePublicationsNearBy, .getUserInfo, .getAllCommentsByPublication:
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
        default:
            return nil
        }
    }
    
    //MARK: - Header
    
    var header: [String : String]? {
        switch self {
        case .postNewPublication(_, _, _, let token):
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
        case .postNewUser(_, let token):
            return [
                "Authorization": "Bearer \(token)",
                "Accept": "application/x-www-form-urlencoded",
                "Content-Type": "application/json"
            ]
        case .getUserInfo(let token):
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
        case .postNewPublication(let text, let latitude, let longitude, _):
            let params: [String: Any] = [
                "text": text,
                "latitude": latitude,
                "longitude": longitude
            ]
            return params
        case .postNewUser(let name, _):
            let params: [String: Any] = [
                "name": name
            ]
            return params
        case .postNewComment(let publicationId, let text, _):
            let params: [String: Any] = [
                "publicationId": publicationId,
                "text": text
            ]
            return params
        case .getActivePublicationsNearBy, .getUserInfo, .likePublication, .unlikePublication, .getAllCommentsByPublication, .deleteComment, .deletePublication:
            return nil
        }
    }
}
