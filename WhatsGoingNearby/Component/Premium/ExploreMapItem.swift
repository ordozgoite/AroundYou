//
//  ExploreMapItem.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 11/05/26.
//

import Foundation
import CoreLocation

enum ExploreMapItem: Identifiable, Decodable {
    case post(MapMarkedPost)
    case cluster(MapPostCluster)
    
    var id: String {
        switch self {
        case .post(let post):
            return "post-\(post.id)"
        case .cluster(let cluster):
            return cluster.id
        }
    }
    
    var coordinate: CLLocationCoordinate2D {
        switch self {
        case .post(let post):
            return CLLocationCoordinate2D(
                latitude: post.latitude,
                longitude: post.longitude
            )
            
        case .cluster(let cluster):
            return CLLocationCoordinate2D(
                latitude: cluster.latitude,
                longitude: cluster.longitude
            )
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
    }
    
    private enum ItemType: String, Decodable {
        case post
        case cluster
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ItemType.self, forKey: .type)
        
        switch type {
        case .post:
            let post = try MapMarkedPost(from: decoder)
            self = .post(post)
            
        case .cluster:
            let cluster = try MapPostCluster(from: decoder)
            self = .cluster(cluster)
        }
    }
}

struct ExploreMapResponse: Decodable {
    let items: [ExploreMapItem]
}

struct MapPostCluster: Identifiable, Decodable {
    let type: String
    let id: String
    let count: Int
    let latitude: Double
    let longitude: Double
    let bounds: MapClusterBounds
    let isPlaceCluster: Bool
    let containsPrivatePosts: Bool
    let isPrivateSinglePostCluster: Bool
    let previewUserProfilePics: [String?]
    let postIds: [String]
    
    private enum CodingKeys: String, CodingKey {
        case type
        case id
        case count
        case latitude
        case longitude
        case bounds
        case isPlaceCluster
        case containsPrivatePosts
        case isPrivateSinglePostCluster
        case previewUserProfilePics
        case postIds
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        type = try container.decode(String.self, forKey: .type)
        id = try container.decode(String.self, forKey: .id)
        count = try container.decode(Int.self, forKey: .count)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        bounds = try container.decode(MapClusterBounds.self, forKey: .bounds)
        
        isPlaceCluster = try container.decodeIfPresent(Bool.self, forKey: .isPlaceCluster) ?? false
        containsPrivatePosts = try container.decodeIfPresent(Bool.self, forKey: .containsPrivatePosts) ?? false
        isPrivateSinglePostCluster = try container.decodeIfPresent(Bool.self, forKey: .isPrivateSinglePostCluster) ?? false
        previewUserProfilePics = try container.decodeIfPresent([String?].self, forKey: .previewUserProfilePics) ?? []
        postIds = try container.decodeIfPresent([String].self, forKey: .postIds) ?? []
    }
    
    var shouldShowPrivateSinglePostMarker: Bool {
        isPrivateSinglePostCluster
    }
}

struct MapClusterBounds: Decodable, Equatable, Hashable {
    let minLat: Double
    let maxLat: Double
    let minLng: Double
    let maxLng: Double
}

extension MapClusterBounds {
    func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        coordinate.latitude >= minLat &&
        coordinate.latitude <= maxLat &&
        coordinate.longitude >= minLng &&
        coordinate.longitude <= maxLng
    }
}
