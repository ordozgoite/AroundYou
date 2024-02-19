//
//  MapScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 18/02/24.
//

import SwiftUI

struct MapScreen: View {
    
    let latitude: Double
    let longitude: Double
    
    var body: some View {
        MapView(latitude: latitude, longitude: longitude)
            .edgesIgnoringSafeArea(.all)
            .navigationTitle("Post Location")
            .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    MapScreen(latitude: -3.125847431319091, longitude: -60.022035207661695)
}
