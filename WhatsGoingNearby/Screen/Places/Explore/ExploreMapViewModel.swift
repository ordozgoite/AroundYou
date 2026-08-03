//
//  ExploreMapViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 09/05/26.
//

import Foundation
import MapKit

extension MKCoordinateRegion {
    var minLat: Double {
        center.latitude - span.latitudeDelta / 2
    }

    var maxLat: Double {
        center.latitude + span.latitudeDelta / 2
    }

    var minLon: Double {
        center.longitude - span.longitudeDelta / 2
    }

    var maxLon: Double {
        center.longitude + span.longitudeDelta / 2
    }
    
    func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        coordinate.latitude >= minLat &&
        coordinate.latitude <= maxLat &&
        coordinate.longitude >= minLon &&
        coordinate.longitude <= maxLon
    }
}

@MainActor
final class ExploreMapViewModel: ObservableObject {
    @Published var items: [ExploreMapItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedPostId: String?

    private var debounceTask: Task<Void, Never>?
    private var currentFetchTask: Task<Void, Never>?

    private var lastFetchedRegion: MKCoordinateRegion?
    private var lastRequestDate: Date?

    private let debounceNanoseconds: UInt64 = 700_000_000
    private let minimumSecondsBetweenRequests: TimeInterval = 1.0
    
    private var requestGeneration = 0
    
    var firebaseUserToken: String? = nil

    func regionDidChange(_ region: MKCoordinateRegion) {
        Task { [weak self] in
            await self?.fetchPostsIfNeeded(for: region)
        }
        
        debounceTask?.cancel()
        
        debounceTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: debounceNanoseconds)
                guard !Task.isCancelled else { return }
                
                await self?.fetchPostsIfNeeded(for: region, force: true)
            } catch {
                return
            }
        }
    }

    func fetchPostsIfNeeded(
        for region: MKCoordinateRegion,
        force: Bool = false
    ) async {
        if !force,
           let lastFetchedRegion,
           !hasRegionChangedEnough(from: lastFetchedRegion, to: region) {
            return
        }

        if !force,
           let lastRequestDate {
            let elapsed = Date().timeIntervalSince(lastRequestDate)

            if elapsed < minimumSecondsBetweenRequests {
                return
            }
        }

        lastFetchedRegion = region
        lastRequestDate = Date()

        currentFetchTask?.cancel()

        requestGeneration += 1
        let generation = requestGeneration

        currentFetchTask = Task { [weak self] in
            await self?.fetchPosts(for: region, generation: generation)
        }
    }

    private func fetchPosts(for region: MKCoordinateRegion, generation: Int) async {
        guard let token = firebaseUserToken else { return }
        
        isLoading = true
        defer { isLoading = false }

        let result = await AYServices.shared.getMapPosts(
            minLat: region.minLat,
            maxLat: region.maxLat,
            minLong: region.minLon,
            maxLong: region.maxLon,
            token: token
        )
        
        switch result {
        case .success(let mapResponse):
            guard generation == requestGeneration else { return }
            self.items = mapResponse.items
            
        case .failure(let error):
            guard generation == requestGeneration else { return }
            print("❌ Error trying to fetch items in region.")
            print(error)
        }
    }

    private func hasRegionChangedEnough(
        from oldRegion: MKCoordinateRegion,
        to newRegion: MKCoordinateRegion
    ) -> Bool {
        let latDifference = abs(oldRegion.center.latitude - newRegion.center.latitude)
        let lngDifference = abs(oldRegion.center.longitude - newRegion.center.longitude)

        let latThreshold = oldRegion.span.latitudeDelta * 0.25
        let lngThreshold = oldRegion.span.longitudeDelta * 0.25

        let zoomChanged = abs(oldRegion.span.latitudeDelta - newRegion.span.latitudeDelta) > oldRegion.span.latitudeDelta * 0.2

        return latDifference > latThreshold ||
               lngDifference > lngThreshold ||
               zoomChanged
    }
}
