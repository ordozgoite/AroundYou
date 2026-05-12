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
    
    private var cachedItemsById: [String: ExploreMapItem] = [:]

    private let debounceNanoseconds: UInt64 = 700_000_000
    private let minimumSecondsBetweenRequests: TimeInterval = 1.0
    
    var firebaseUserToken: String? = nil

    func regionDidChange(_ region: MKCoordinateRegion) {
        refreshDisplayedItemsFromCache(for: region)
        
        debounceTask?.cancel()

        debounceTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: debounceNanoseconds)

                guard !Task.isCancelled else { return }

                await self?.fetchPostsIfNeeded(for: region)
            } catch {
                return
            }
        }
    }

    func fetchPostsIfNeeded(for region: MKCoordinateRegion) async {
        if let lastFetchedRegion,
           !hasRegionChangedEnough(from: lastFetchedRegion, to: region) {
            return
        }

        if let lastRequestDate {
            let elapsed = Date().timeIntervalSince(lastRequestDate)

            if elapsed < minimumSecondsBetweenRequests {
                return
            }
        }

        lastFetchedRegion = region
        lastRequestDate = Date()

        currentFetchTask?.cancel()

        currentFetchTask = Task { [weak self] in
            await self?.fetchPosts(for: region)
        }
    }

    private func fetchPosts(for region: MKCoordinateRegion) async {
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
            mergeItemsIntoCache(mapResponse.items)
            refreshDisplayedItemsFromCache(for: region)
            
        case .failure(let error):
            print("❌ Error trying to fetch items in region.")
            print(error)
        }
    }
    
    private func mergeItemsIntoCache(_ newItems: [ExploreMapItem]) {
        for item in newItems {
            cachedItemsById[item.id] = item
        }
    }
    
    private func refreshDisplayedItemsFromCache(for region: MKCoordinateRegion) {
        let cachedItems = Array(cachedItemsById.values)
        let visibleItems = cachedItems.filter { item in
            region.contains(item.coordinate)
        }
        
        guard !visibleItems.isEmpty else {
            return
        }
        
        items = filteredItemsForCurrentZoom(
            visibleItems,
            region: region
        )
    }
    
    private func filteredItemsForCurrentZoom(
        _ cachedItems: [ExploreMapItem],
        region: MKCoordinateRegion
    ) -> [ExploreMapItem] {
        if shouldShowOnlyIndividualPosts(region) {
            return cachedItems.filter { item in
                if case .post = item {
                    return true
                }
                
                return false
            }
        }
        
        let currentResolution = h3Resolution(for: region)
        
        let clusters = cachedItems.filter { item in
            guard case .cluster(let cluster) = item else {
                return false
            }
            
            return cluster.h3Resolution == currentResolution
        }
        
        let posts = cachedItems.filter { item in
            guard case .post(let post) = item else {
                return false
            }
            
            let postCoordinate = CLLocationCoordinate2D(
                latitude: post.latitude,
                longitude: post.longitude
            )
            
            let isCoveredByCluster = clusters.contains { clusterItem in
                guard case .cluster(let cluster) = clusterItem else {
                    return false
                }
                
                return cluster.bounds.contains(postCoordinate)
            }
            
            return !isCoveredByCluster
        }
        
        return clusters + posts
    }
    
    private func h3Resolution(for region: MKCoordinateRegion) -> Int {
        let largestDelta = largestDelta(for: region)
        
        if largestDelta > 0.08 { return 7 }
        if largestDelta > 0.04 { return 8 }
        if largestDelta > 0.02 { return 9 }
        if largestDelta > 0.008 { return 10 }
        
        return 11
    }
    
    private func shouldShowOnlyIndividualPosts(_ region: MKCoordinateRegion) -> Bool {
        largestDelta(for: region) <= 0.004
    }
    
    private func largestDelta(for region: MKCoordinateRegion) -> Double {
        max(region.span.latitudeDelta, region.span.longitudeDelta)
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
