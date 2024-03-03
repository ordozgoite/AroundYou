//
//  MapViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 02/03/24.
//

import Foundation
import MapKit

@MainActor
class MapViewModel: ObservableObject {
    
    @Published var posts: [FormattedPost] = []
    
    @Published var isLoading: Bool = false
    
    func getPostsNearBy(latitude: Double, longitude: Double, token: String) async {
        isLoading = true
        let response = await AYServices.shared.getActivePublicationsNearBy(latitude: latitude, longitude: longitude, token: token)
        isLoading = false
        
        switch response {
        case .success(let posts):
            self.posts = posts
        case .failure(let error):
            print("❌ Error: \(error)")
        }
    }
}
