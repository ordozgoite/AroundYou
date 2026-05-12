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
}

struct MapClusterBounds: Decodable {
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

extension MapPostCluster {
    var h3Resolution: Int? {
        let components = id.split(separator: ":")
        
        guard components.count >= 4 else {
            return nil
        }
        
        return Int(components[2])
    }
}
