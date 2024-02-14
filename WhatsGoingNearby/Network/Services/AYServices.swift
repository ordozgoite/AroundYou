//
//  AYServices.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 14/02/24.
//

import Foundation

protocol AYServiceable {
    
    // Publication
    func postNewPublication(text: String, timestamp: Int, latitude: Double, longitude: Double, token: String) async -> Result<Post, RequestError>
    func getActivePublicationsNearBy(latitude: Double, longitude: Double, token: String) async -> Result<[FormattedPost], RequestError>
}

struct AYServices: HTTPClient, AYServiceable {
    
    static let shared = AYServices()
    private init() {}
    
    //MARK: - Publication
    
    func postNewPublication(text: String, timestamp: Int, latitude: Double, longitude: Double, token: String) async -> Result<Post, RequestError> {
        return await sendRequest(endpoint: AYEndpoints.postNewPublication(text: text, timestamp: timestamp, latitude: latitude, longitude: longitude, token: token), responseModel: Post.self)
    }
    
    func getActivePublicationsNearBy(latitude: Double, longitude: Double, token: String) async -> Result<[FormattedPost], RequestError> {
        return await sendRequest(endpoint: AYEndpoints.getActivePublicationsNearBy(latitude: latitude, longitude: longitude, token: token), responseModel: [FormattedPost].self)
    }
}
