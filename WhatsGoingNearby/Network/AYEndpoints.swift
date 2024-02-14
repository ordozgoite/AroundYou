//
//  AYEndpoints.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 14/02/24.
//

import Foundation

enum AYEndpoints {
    case postNewPublication(text: String, timestamp: Int, latitude: Double, longitude: Double, token: String)
    case getActivePublicationsNearBy(latitude: Double, longitude: Double, token: String)
}

extension AYEndpoints: Endpoint {
    
    //MARK: - URL
    
    var path: String {
        switch self{
        case .postNewPublication:
            return "/api/Publication/PostNewPublication"
        case .getActivePublicationsNearBy:
            return "/api/Publication/GetActivePublicationsNearBy"
        }
    }
    
    //MARK: - Method
    
    var method: RequestMethod {
        switch self {
        case .postNewPublication:
            return .post
        case .getActivePublicationsNearBy:
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
        case .postNewPublication(let text, let timestamp, let latitude, let longitude, _):
            let params: [String: Any] = [
                "text": text,
                "timestamp": timestamp,
                "latitude": latitude,
                "longitude": longitude
            ]
            return params
        case .getActivePublicationsNearBy:
            return nil
        }
    }
}
