//
//  MapScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 18/02/24.
//

import SwiftUI
import MapKit

@available(iOS 17.0, *)
struct NewMapScreen: View {
    
    let latitude: Double
    let longitude: Double
    let userName: String
    
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    
    var body: some View {
        Map(position: $position) {
            Annotation(
                userName,
                coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                anchor: .bottom
            ) {
                Image("shaq")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            }
            
            UserAnnotation()
        }
        .navigationTitle("Post Location")
    }
}
