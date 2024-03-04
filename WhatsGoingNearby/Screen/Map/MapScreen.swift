//
//  MapScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 02/03/24.
//

import SwiftUI
import MapKit

@available(iOS 17.0, *)
struct MapScreen: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @ObservedObject private var mapVM = MapViewModel()
    
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var visibleRegion: MKCoordinateRegion?
    
    @State private var isSheetPresented: Bool = true
    
    var body: some View {
        Map(position: $position) {
            UserAnnotation()
            
            ForEach(mapVM.posts) { post in
                if let latitude = post.latitude, let longitude = post.longitude {
                    Annotation(
                        post.username,
                        coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                        anchor: .bottom
                    ) {
                        Image(systemName: "bubble.left.circle.fill")
                            .resizable()
                            .frame(width: 32, height: 32, alignment: .center)
                            .aspectRatio(contentMode: .fit)
                            .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.red, .blue]), startPoint: .topLeading, endPoint: .bottomTrailing))
                            .shadow(color: .black, radius: 2.5, x: 1, y: 1)
                    }
                }
            }
        }
        //        .safeAreaInset(edge: .bottom) {
        //            Search()
        //        }
//        .sheet(isPresented: $isSheetPresented) {
//            SheetView()
//        }
        .onMapCameraChange { context in
            visibleRegion = context.region
        }
        .navigationTitle("Map")
    }
    
    //MARK: - Search Settings
    
    @ViewBuilder
    private func Search() -> some View {
        VStack {
            HStack {
                AYButton(title: "Search Around You") {
                    Task {
                        if let latitude = visibleRegion?.center.latitude, let longitude = visibleRegion?.center.longitude {
                            let token = try await authVM.getFirebaseToken()
                            await mapVM.getPostsNearBy(latitude: latitude, longitude: longitude, token: token)
                        }
                    }
                }
            }
            .padding()
        }
        .background(.thinMaterial)
    }
}

//#Preview {
//    MapScreen()
//}
