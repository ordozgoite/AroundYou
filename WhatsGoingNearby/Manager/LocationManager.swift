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

    private var oneShotContinuation: CheckedContinuation<CLLocation?, Never>?

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

    /// Busca a localização atual de forma assíncrona (single-shot), sem depender de uma
    /// sessão de `startUpdatingLocation()` já ativa. Usado pela background task, onde o app
    /// pode ser relançado do zero e nenhuma View ainda chamou `requestLocation()`.
    /// Retorna `nil` se não houver autorização ou se nenhuma localização chegar no `timeout`.
    func getCurrentLocation(timeout: TimeInterval = 15) async -> CLLocation? {
        guard isLocationAuthorized else { return nil }

        return await withTaskGroup(of: CLLocation?.self) { group in
            group.addTask {
                await withCheckedContinuation { continuation in
                    self.oneShotContinuation = continuation
                    self.locationManager.requestLocation()
                }
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                return nil
            }
            let result = await group.next() ?? nil
            group.cancelAll()
            return result
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.first else { return }

        if location == nil || newLocation.distance(from: location!) >= Constants.SIGNIFICANT_DISTANCE_METERS {
            self.location = newLocation
            notifyLocationSensitiveDataRefresh()
        }

        oneShotContinuation?.resume(returning: newLocation)
        oneShotContinuation = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse {
            self.locationManager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
        oneShotContinuation?.resume(returning: nil)
        oneShotContinuation = nil
    }

    private func notifyLocationSensitiveDataRefresh() {
        NotificationCenter.default.post(name: .refreshLocationSensitiveData, object: nil)
    }

    @objc private func updateLocation() {
        self.location = nil
    }
}

