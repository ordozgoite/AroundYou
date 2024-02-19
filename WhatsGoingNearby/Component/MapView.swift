//
//  MapView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 18/02/24.
//

import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    let latitude: Double
    let longitude: Double

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.showsUserLocation = true
        return mapView
    }

    func updateUIView(_ view: MKMapView, context: Context) {
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let region = MKCoordinateRegion(center: location, span: span)
        view.setRegion(region, animated: true)

        let annotation = MKPointAnnotation()
        annotation.coordinate = location
        view.addAnnotation(annotation)
    }
}
