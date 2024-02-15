//
//  AYServices.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 14/02/24.
//

import Foundation

protocol AYServiceable {
    
    // User
    func postNewUser(name: String, token: String) async -> Result<MongoUser, RequestError>
    func getUserInfo(token: String) async -> Result<MongoUser, RequestError>
    func getUserProfile(userUid: String, token: String) async ->Result<UserProfile, RequestError>
    
    // Publication
    func postNewPublication(text: String, latitude: Double, longitude: Double, token: String) async -> Result<Post, RequestError>
    func deletePublication(publicationId: String, token: String) async -> Result<DeletePublicationResponse, RequestError>
    func getActivePublicationsNearBy(latitude: Double, longitude: Double, token: String) async -> Result<[FormattedPost], RequestError>
    func likePublication(publicationId: String, token: String) async -> Result<LikePublicationResponse, RequestError>
    func unlikePublication(publicationId: String, token: String) async -> Result<UnlikePublicationResponse, RequestError>
    
    // Comment
    func postNewComment(publicationId: String, text: String, token: String) async -> Result<PostNewCommentResponse, RequestError>
    func deleteComment(commentId: String, token: String) async -> Result<DeleteCommentResponse, RequestError>
    func getAllCommentsByPublication(publicationId: String, token: String) async -> Result<[FormattedComment], RequestError>
}

struct AYServices: HTTPClient, AYServiceable {
    
    static let shared = AYServices()
    private init() {}
    
    //MARK: - User
    
    func postNewUser(name: String, token: String) async -> Result<MongoUser, RequestError> {
        return await sendRequest(endpoint: AYEndpoints.postNewUser(name: name, token: token), responseModel: MongoUser.self)
    }
    
    func getUserInfo(token: String) async -> Result<MongoUser, RequestError> {
        return await sendRequest(endpoint: AYEndpoints.getUserInfo(token: token), responseModel: MongoUser.self)
    }
    
    func getUserProfile(userUid: String, token: String) async -> Result<UserProfile, RequestError> {
        return await sendRequest(endpoint: AYEndpoints.getUserProfile(userUid: userUid, token: token), responseModel: UserProfile.self)
    }
    
    //MARK: - Publication
    
    func postNewPublication(text: String, latitude: Double, longitude: Double, token: String) async -> Result<Post, RequestError> {
        return await sendRequest(endpoint: AYEndpoints.postNewPublication(text: text, latitude: latitude, longitude: longitude, token: token), responseModel: Post.self)
    }
    
    func deletePublication(publicationId: String, token: String) async -> Result<DeletePublicationResponse, RequestError> {
        return await sendRequest(endpoint: AYEndpoints.deletePublication(publicationId: publicationId, token: token), responseModel: DeletePublicationResponse.self)
    }
    
    func getActivePublicationsNearBy(latitude: Double, longitude: Double, token: String) async -> Result<[FormattedPost], RequestError> {
        return await sendRequest(endpoint: AYEndpoints.getActivePublicationsNearBy(latitude: latitude, longitude: longitude, token: token), responseModel: [FormattedPost].self)
    }
    
    func likePublication(publicationId: String, token: String) async -> Result<LikePublicationResponse, RequestError> {
        return await sendRequest(endpoint: AYEndpoints.likePublication(publicationId: publicationId, token: token), responseModel: LikePublicationResponse.self)
    }
    
    func unlikePublication(publicationId: String, token: String) async -> Result<UnlikePublicationResponse, RequestError> {
        return await sendRequest(endpoint: AYEndpoints.unlikePublication(publicationId: publicationId, token: token), responseModel: UnlikePublicationResponse.self)
    }
    
    //MARK: - Comment
    
    func postNewComment(publicationId: String, text: String, token: String) async -> Result<PostNewCommentResponse, RequestError> {
        return await sendRequest(endpoint: AYEndpoints.postNewComment(publicationId: publicationId, text: text, token: token), responseModel: PostNewCommentResponse.self)
    }
    
    func deleteComment(commentId: String, token: String) async -> Result<DeleteCommentResponse, RequestError> {
        return await sendRequest(endpoint: AYEndpoints.deleteComment(commentId: commentId, token: token), responseModel: DeleteCommentResponse.self)
    }
    
    func getAllCommentsByPublication(publicationId: String, token: String) async -> Result<[FormattedComment], RequestError> {
        return await sendRequest(endpoint: AYEndpoints.getAllCommentsByPublication(publicationId: publicationId, token: token), responseModel: [FormattedComment].self)
    }
}
