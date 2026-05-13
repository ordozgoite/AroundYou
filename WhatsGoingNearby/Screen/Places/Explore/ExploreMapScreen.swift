//
//  ExploreMapScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 09/05/26.
//

import SwiftUI
import MapKit

struct ExploreMapScreen: View {
    
    @StateObject private var viewModel = ExploreMapViewModel()
    @EnvironmentObject var authVM: AuthenticationViewModel
    @EnvironmentObject var navCoordinator: NavigationCoordinator
    @EnvironmentObject var locationManager: LocationManager
    
    @Namespace private var mapPostMarkerAnimation
    
    @State private var region: MKCoordinateRegion?
    @State private var didCenterOnUserLocation = false
    
    private let initialLatitudeDelta: CLLocationDegrees = 0.02
    private let initialLongitudeDelta: CLLocationDegrees = 0.02
    
    private let maxLatitudeDelta: CLLocationDegrees = 0.08
    private let maxLongitudeDelta: CLLocationDegrees = 0.08
    
    private var selectedPost: MapMarkedPost? {
        guard let selectedPostId = viewModel.selectedPostId else {
            return nil
        }
        
        return viewModel.items.compactMap { item in
            if case .post(let post) = item, post.id == selectedPostId {
                return post
            }
            
            return nil
        }.first
    }
    
    private var orderedMapItems: [ExploreMapItem] {
        guard let selectedPostId = viewModel.selectedPostId else {
            return viewModel.items
        }
        
        return viewModel.items.sorted(by: { (first: ExploreMapItem, second: ExploreMapItem) in
            if first.isPost(id: selectedPostId) {
                return false
            }
            
            if second.isPost(id: selectedPostId) {
                return true
            }
            
            return first.zIndex < second.zIndex
        })
    }
    
    var body: some View {
        ZStack {
            if region != nil {
                Map(
                    coordinateRegion: regionBinding,
                    interactionModes: [.pan, .zoom],
                    showsUserLocation: true,
                    annotationItems: orderedMapItems
                ) { item in
                    MapAnnotation(coordinate: item.coordinate) {
                        switch item {
                        case .post(let post):
                            MapPostAnnotationView(
                                post: post,
                                isSelected: viewModel.selectedPostId == post.id,
                                namespace: mapPostMarkerAnimation,
                                onSelect: {
                                    withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                                        viewModel.selectedPostId = post.id
                                    }
                                }
                            )
                            .zIndex(viewModel.selectedPostId == post.id ? 999 : 0)
                            
                        case .cluster(let cluster):
                            ClusterMapMarker(cluster: cluster)
                                .onTapGesture {
                                    openClusterPosts(cluster)
                                }
                                .zIndex(100)
                        }
                    }
                }
                .ignoresSafeArea()
                .onChange(of: region?.center.latitude) { _ in
                    handleRegionChange()
                }
                .onChange(of: region?.center.longitude) { _ in
                    handleRegionChange()
                }
                .onChange(of: region?.span.latitudeDelta) { _ in
                    handleRegionChange()
                }
                .onChange(of: region?.span.longitudeDelta) { _ in
                    handleRegionChange()
                }
            } else {
                waitingForLocationView
            }
            
            VStack {
                topBar
                Spacer()
            }
            .zIndex(200)
            
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    recenterButton
                        .padding(.trailing, 16)
                        .padding(.bottom, selectedPost == nil ? 32 : 150)
                }
            }
            .zIndex(250)
            
            if let errorMessage = viewModel.errorMessage {
                VStack {
                    Spacer()
                    
                    Text(errorMessage)
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.bottom, 32)
                }
                .zIndex(300)
            }
            
            if selectedPost != nil {
                Color.black
                    .opacity(0.08)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            viewModel.selectedPostId = nil
                        }
                    }
                    .transition(.opacity)
                    .zIndex(500)
            }
            
            if let selectedPost {
                VStack {
                    Spacer()
                    
                    ExpandedPostMapMarker(
                        post: selectedPost,
                        namespace: mapPostMarkerAnimation,
                        onTap: {
                            openPostDetails(selectedPost)
                        }
                    )
                    .padding(.bottom, 32)
                }
                .padding(.horizontal, 16)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1000)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.selectedPostId)
        .onReceive(locationManager.$location) { location in
            centerMapOnUserLocationIfNeeded(location)
        }
        .onAppear {
            Task {
                viewModel.firebaseUserToken = try await authVM.getFirebaseToken()
                requestCurrentLocation()
            }
        }
    }
    
    private var regionBinding: Binding<MKCoordinateRegion> {
        Binding(
            get: {
                region ?? MKCoordinateRegion()
            },
            set: { newRegion in
                DispatchQueue.main.async {
                    region = newRegion
                }
            }
        )
    }
    
    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Explore")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Move the map to discover posts nearby")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if viewModel.isLoading || region == nil {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
    private var recenterButton: some View {
        Button {
            recenterMapOnCurrentLocation()
        } label: {
            Image(systemName: "location.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 48, height: 48)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
        }
    }
    
    private var waitingForLocationView: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            ProgressView()
                .controlSize(.large)
        }
    }
    
    private func requestCurrentLocation() {
        if let location = locationManager.location {
            centerMapOnUserLocationIfNeeded(location)
            return
        }
        
        locationManager.requestLocation()
    }
    
    private func centerMapOnUserLocationIfNeeded(_ location: CLLocation?) {
        guard !didCenterOnUserLocation else { return }
        guard let location else { return }
        
        didCenterOnUserLocation = true
        centerMap(on: location, animated: false)
    }
    
    private func recenterMapOnCurrentLocation() {
        if let location = locationManager.location {
            centerMap(on: location, animated: true)
        } else {
            locationManager.requestLocation()
        }
    }
    
    private func centerMap(on location: CLLocation, animated: Bool) {
        let updatedRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            ),
            span: MKCoordinateSpan(
                latitudeDelta: initialLatitudeDelta,
                longitudeDelta: initialLongitudeDelta
            )
        )
        
        if animated {
            withAnimation(.easeInOut(duration: 0.45)) {
                region = updatedRegion
            }
        } else {
            region = updatedRegion
        }
        
        viewModel.regionDidChange(updatedRegion)
    }
    
    private func handleRegionChange() {
        limitZoomOutIfNeeded()
        
        guard let region else { return }
        viewModel.regionDidChange(region)
    }
    
    private func limitZoomOutIfNeeded() {
        guard let currentRegion = region else { return }
        
        var updatedRegion = currentRegion
        var shouldUpdate = false
        
        if currentRegion.span.latitudeDelta > maxLatitudeDelta {
            updatedRegion.span.latitudeDelta = maxLatitudeDelta
            shouldUpdate = true
        }
        
        if currentRegion.span.longitudeDelta > maxLongitudeDelta {
            updatedRegion.span.longitudeDelta = maxLongitudeDelta
            shouldUpdate = true
        }
        
        if shouldUpdate {
            DispatchQueue.main.async {
                region = updatedRegion
            }
        }
    }
    
    private func openPostDetails(_ post: MapMarkedPost) {
        // navCoordinator.navigate(to: .comment)
        print("Open post details:", post.id)
    }
    
    private func openClusterPosts(_ cluster: MapPostCluster) {
        print("🚨 openClusterPosts")
        navCoordinator.navigate(to: .clusterPosts(cluster.bounds))
    }
}

struct MapPostAnnotationView: View {
    
    let post: MapMarkedPost
    let isSelected: Bool
    let namespace: Namespace.ID
    let onSelect: () -> Void
    
    var body: some View {
        PostMapMarker(
            post: post,
            namespace: namespace
        )
        .opacity(isSelected ? 0.001 : 1)
        .onTapGesture {
            onSelect()
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.86), value: isSelected)
    }
}

private extension ExploreMapItem {
    
    var zIndex: Double {
        switch self {
        case .post:
            return 0
        case .cluster:
            return 100
        }
    }
    
    func isPost(id postId: String) -> Bool {
        switch self {
        case .post(let post):
            return post.id == postId
        case .cluster:
            return false
        }
    }
}
