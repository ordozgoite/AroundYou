//
//  MapScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 18/02/24.
//

import SwiftUI
import MapKit

@available(iOS 17.0, *)
struct NewPostLocationScreen: View {
    
    let latitude: Double
    let longitude: Double
    let username: String
    let profilePic: String?
    @State private var position: MapCameraPosition = .automatic
    
    var body: some View {
        Map(position: $position) {
            Annotation(
                username,
                coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                anchor: .bottom
            ) {
                ProfilePic()
            }
            
            UserAnnotation()
        }
        .onAppear {
            position = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            ))
        }
        .navigationTitle("Post Location")
    }
    
    //MARK: - Profile Pic
    
    @ViewBuilder
    private func ProfilePic() -> some View {
        VStack {
            ZStack {
                Circle()
                    .fill(.white)
                    .frame(width: 54, height: 54)
                
                if let url = profilePic {
                    ProfilePicView(profilePic: url, size: 50)
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .foregroundStyle(.gray)
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                }
            }
            
            Circle()
                .fill(.white)
                .frame(width: 8, height: 8)
        }
        .shadow(color: .black, radius: 2.5, x: 1, y: 1)
    }
}
