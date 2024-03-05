//
//  CalculateDistanceTestScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 14/02/24.
//

import SwiftUI

struct CalculateDistanceTestScreen: View {
    
    @State private var latitude1: String = ""
    @State private var longitude1: String = ""
    @State private var latitude2: String = ""
    @State private var longitude2: String = ""
    @State private var distance: String = ""
    
    var body: some View {
        VStack {
            Text("First Location")
            
            HStack {
                TextField("Latitude", text: $latitude1)
                TextField("Longitude", text: $longitude1)
            }
            
            Text("Second Location")
            
            HStack {
                TextField("Latitude", text: $latitude2)
                TextField("Longitude", text: $longitude2)
            }
            
            Button("Calculate Distance") {
                haversine(lat1: Double(latitude1)!, lon1: Double(longitude1)!, lat2: Double(latitude2)!, lon2: Double(longitude2)!)
            }
            
            if !distance.isEmpty {
                Text("Distance: \(distance) meters")
            }
        }
    }
    
    private func haversine(lat1: Double, lon1: Double, lat2: Double, lon2: Double) {
        let R = 6371000.0  // raio da Terra em metros
        let phi1 = lat1 * .pi / 180.0
        let phi2 = lat2 * .pi / 180.0
        let deltaPhi = (lat2 - lat1) * .pi / 180.0
        let deltaLambda = (lon2 - lon1) * .pi / 180.0

        let a = sin(deltaPhi/2) * sin(deltaPhi/2) + cos(phi1) * cos(phi2) * sin(deltaLambda/2) * sin(deltaLambda/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        let d = R * c

        self.distance = String(d)
    }
}

#Preview {
    CalculateDistanceTestScreen()
}
