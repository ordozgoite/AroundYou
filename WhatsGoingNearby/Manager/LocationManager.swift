//
//  LocationManager.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 14/02/24.
//

import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    private var locationManager = CLLocationManager()
    @Published var location: CLLocation?
    
    var isLocationAuthorized: Bool {
        return locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways
    }
    
    var isUsingFullAccuracy: Bool {
        return locationManager.accuracyAuthorization == .fullAccuracy
    }
    
    override init() {
        super.init()
        self.locationManager.delegate = self
        addObservers()
    }
    
    private func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateLocation), name: Notification.Name(Constants.updateLocationNotificationKey), object: nil)
    }
    
    func requestLocation() {
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.first else { return }
        
        if location == nil || newLocation.distance(from: location!) >= Constants.significantDistanceMeters {
            self.location = newLocation
            notifyLocationSensitiveDataRefresh()
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse {
            self.locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
    
    private func notifyLocationSensitiveDataRefresh() {
        let name = Notification.Name(Constants.refreshLocationSensitiveDataNotificationKey)
        NotificationCenter.default.post(name: name, object: nil)
    }
    
    @objc private func updateLocation() {
        self.location = nil
    }
}

