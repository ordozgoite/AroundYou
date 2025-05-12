//
//  UserDiscover.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 15/01/25.
//

import Foundation

struct UserDiscoverInfo: Codable, Identifiable {
    let id = UUID()
    let userUid: String
    let username: String
    let profilePic: String?
    let locationLastUpdateAt: Int
    let gender: String
    let age: Int
    
    var genderEnum: Gender {
        switch self.gender {
        case "cis-male":
            return  .cisMale
        case "cis-female":
            return .cisFemale
        case "trans-male":
            return .transMale
        case "trans-female":
            return .transFemale
        default:
            return .cisMale // never should be reachable
        }
    }
}
