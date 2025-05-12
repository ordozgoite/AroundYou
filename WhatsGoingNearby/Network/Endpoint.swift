//
//  Endpoint.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 14/02/24.
//

import Foundation

public typealias route = URLRequest

protocol Endpoint {
    var baseUrl: URL { get }
    var path: String { get }
    var method: RequestMethod { get }
    var header: [String: String]? { get }
    var query: [String: Any]? { get }
    var body: [String: Any]? { get }
}

extension Endpoint {
    
    var baseUrl: URL {
        return URL(string: Constants.API_URL)!
//        return URL(string: "http://localhost:3000")!
    }
}

public enum RequestMethod: String {
    case delete = "DELETE"
    case get = "GET"
    case post = "POST"
    case put = "PUT"
}

enum RequestError: Error {
    case decode
    case invalidURL
    case noResponse
    case unauthorized
    case dataNotFound
    case conflict
    case incorrectOTP
    case unexpectedStatusCode
    case forbidden
    case unknown
    case badRequest
    case unprocessableEntity
    case locked
    
    var customMessage: String {
        switch self {
        case .decode:
            return "Decode error"
        case .unauthorized:
            return "Session expired"
        case .unexpectedStatusCode:
            return "Something went wrong, please try again later"
        case .dataNotFound:
            return "Data not found"
        case .incorrectOTP:
            return "You entered incorrect OTP"
        case .conflict:
            return "Conflict data"
        case .unprocessableEntity:
            return "The request could not be processed due to semantic errors."
        case .locked:
            return "Access denied: the requested resource is locked."
        default:
            return "Unknown error"
        }
    }
}
