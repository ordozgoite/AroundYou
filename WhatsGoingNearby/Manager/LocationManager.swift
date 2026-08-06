//
//  LocationManager.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 14/02/24.
//

import Foundation
import CoreLocation

enum LocationError: Error {
    case unableToGetCurrentLocation
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    // Compartilhado entre o AppDelegate (background task) e a árvore de Views (environmentObject),
    // para que ambos observem as mesmas atualizações de localização.
    static let shared = LocationManager()

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
        NotificationCenter.default.addObserver(self, selector: #selector(updateLocation), name: .updateLocation, object: nil)
    }

    func requestLocation() {
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
    }

    func locationForBackgroundRefresh() -> CLLocation? {
        if let location, isValidBackgroundLocation(location) {
            return location
        }

        return LocalState.lastKnownLocation(
            maxAge: Constants.MAX_BACKGROUND_LOCATION_AGE_SECONDS,
            maximumAccuracy: Constants.MAX_BACKGROUND_LOCATION_ACCURACY_METERS
        )
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }

        if isValidBackgroundLocation(newLocation) {
            LocalState.saveLastKnownLocation(newLocation)
        }

        if location == nil || newLocation.distance(from: location!) >= Constants.SIGNIFICANT_DISTANCE_METERS {
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
        NotificationCenter.default.post(name: .refreshLocationSensitiveData, object: nil)
    }

    private func isValidBackgroundLocation(_ location: CLLocation) -> Bool {
        let age = Date().timeIntervalSince(location.timestamp)
        return CLLocationCoordinate2DIsValid(location.coordinate)
            && age >= -60
            && age <= Constants.MAX_BACKGROUND_LOCATION_AGE_SECONDS
            && location.horizontalAccuracy >= 0
            && location.horizontalAccuracy <= Constants.MAX_BACKGROUND_LOCATION_ACCURACY_METERS
    }

    @objc private func updateLocation() {
        self.location = nil
    }
}
