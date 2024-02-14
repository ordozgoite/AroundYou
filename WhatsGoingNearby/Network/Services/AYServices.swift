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
    
    // Publication
    func postNewPublication(text: String, timestamp: Int, latitude: Double, longitude: Double, token: String) async -> Result<Post, RequestError>
    func getActivePublicationsNearBy(latitude: Double, longitude: Double, token: String) async -> Result<[FormattedPost], RequestError>
    func likePublication(publicationId: String, token: String) async -> Result<LikePublicationResponse, RequestError>
    func unlikePublication(publicationId: String, token: String) async -> Result<UnlikePublicationResponse, RequestError>
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
    
    //MARK: - Publication
    
    func postNewPublication(text: String, timestamp: Int, latitude: Double, longitude: Double, token: String) async -> Result<Post, RequestError> {
        return await sendRequest(endpoint: AYEndpoints.postNewPublication(text: text, timestamp: timestamp, latitude: latitude, longitude: longitude, token: token), responseModel: Post.self)
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
}
