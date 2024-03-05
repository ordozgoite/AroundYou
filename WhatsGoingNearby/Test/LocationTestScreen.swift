//
//  LocationTestScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 14/02/24.
//

import SwiftUI
import CoreLocationUI

struct LocationTestScreen: View {
    
    @ObservedObject var locationManager = LocationManager()
    
    var body: some View {
        VStack {
            if let location = locationManager.location {
                Text("Your location:")
                Text("Latitude: \(location.coordinate.latitude)")
                Text("Longitude: \(location.coordinate.longitude)")
                
                Button("print location") {
                    print("Latitude: \(location.coordinate.latitude)")
                    print("Longitude: \(location.coordinate.longitude)")
                }
            } else {
                AYProgressView()
            }
        }
        .onAppear {
            locationManager.requestLocation()
        }
    }
}

#Preview {
    LocationTestScreen()
}
