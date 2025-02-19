//
//  CommunityDetailViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 19/02/25.
//

import Foundation

@MainActor
class CommunityDetailViewModel: ObservableObject {
    
    var members: [MongoUser] = [
        MongoUser(userUid: "1", username: "ordozgoite", name: nil, profilePic: nil, biography: nil),
        MongoUser(userUid: "2", username: "amanda", name: nil, profilePic: nil, biography: nil),
        MongoUser(userUid: "3", username: "igor", name: nil, profilePic: nil, biography: nil)
    ]
    var joinRequests: [MongoUser] = [
        MongoUser(userUid: "4", username: "bruno", name: nil, profilePic: nil, biography: nil)
    ]
    var communityOwnerUid: String = "1"
    
    func getCommunityInfo() async {
        
    }
    
    func leaveCommunity() async {
        
    }
    
    func deleteCommunity() async {
        
    }
}
