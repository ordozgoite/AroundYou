//
//  MapMarkedPost.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 10/05/26.
//

import Foundation

struct MapMarkedPost: Identifiable, Decodable {
    let id: String
    let userUid: String
    let userProfilePic: String?
    let username: String
    let timestamp: Int
    let expirationDate: Int
    let text: String?
    let tag: String?
    let imageUrl: String?
    var videoUrl: String? = nil
    var videoThumbnailUrl: String? = nil
    let isOwnerFarAway: Bool?
    let duration: Int?
    let isFinished: Bool
    let isLocationVisible: Bool
    let latitude: Double
    let longitude: Double
}

extension MapMarkedPost {

    /// A API devolve uma coordenada com jitter quando o autor optou por não revelar a localização,
    /// então o marcador precisa avisar que o ponto no mapa é aproximado.
    var hasApproximateLocation: Bool {
        !isLocationVisible
    }
}

extension MapMarkedPost {
    static let mock = MapMarkedPost(
        id: "post_001",
        userUid: "user_12345",
        userProfilePic: "https://i.pravatar.cc/300?img=12",
        username: "Victor",
        timestamp: 1_767_969_600,
        expirationDate: 1_768_056_000,
        text: "Alguém por aqui quer tomar um café?",
        tag: "coffee",
        imageUrl: "https://images.unsplash.com/photo-1509042239860-f550ce710b93",
        isOwnerFarAway: false,
        duration: 24,
        isFinished: false,
        isLocationVisible: true,
        latitude: -3.101944,
        longitude: -60.025000
    )
}
