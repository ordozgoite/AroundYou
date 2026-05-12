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
    
    @Namespace private var mapPostMarkerAnimation
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -3.1190, longitude: -60.0217),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )
    
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
            Map(
                coordinateRegion: $region,
                interactionModes: [.pan, .zoom],
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
                                zoomIntoCluster(cluster)
                            }
                            .zIndex(100)
                    }
                }
            }
            .ignoresSafeArea()
            .onAppear {
                viewModel.regionDidChange(region)
            }
            .onChange(of: region.center.latitude) { _ in
                handleRegionChange()
            }
            .onChange(of: region.center.longitude) { _ in
                handleRegionChange()
            }
            .onChange(of: region.span.latitudeDelta) { _ in
                handleRegionChange()
            }
            .onChange(of: region.span.longitudeDelta) { _ in
                handleRegionChange()
            }
            
            VStack {
                topBar
                
                Spacer()
                
                if viewModel.isLoading {
                    loadingView
                        .padding(.bottom, 32)
                }
            }
            .zIndex(200)
            
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
        .onAppear {
            Task {
                viewModel.firebaseUserToken = try await authVM.getFirebaseToken()
            }
        }
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
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
    private var loadingView: some View {
        HStack(spacing: 8) {
            ProgressView()
            
            Text("Loading posts in this area...")
                .font(.subheadline)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
    
    private func handleRegionChange() {
        limitZoomOutIfNeeded()
        viewModel.regionDidChange(region)
    }
    
    private func limitZoomOutIfNeeded() {
        var updatedRegion = region
        var shouldUpdate = false
        
        if region.span.latitudeDelta > maxLatitudeDelta {
            updatedRegion.span.latitudeDelta = maxLatitudeDelta
            shouldUpdate = true
        }
        
        if region.span.longitudeDelta > maxLongitudeDelta {
            updatedRegion.span.longitudeDelta = maxLongitudeDelta
            shouldUpdate = true
        }
        
        if shouldUpdate {
            DispatchQueue.main.async {
                region = updatedRegion
            }
        }
    }
    
    private func zoomIntoCluster(_ cluster: MapPostCluster) {
        let center = CLLocationCoordinate2D(
            latitude: (cluster.bounds.minLat + cluster.bounds.maxLat) / 2,
            longitude: (cluster.bounds.minLng + cluster.bounds.maxLng) / 2
        )
        
        let latitudeDelta = max(
            (cluster.bounds.maxLat - cluster.bounds.minLat) * 2.2,
            region.span.latitudeDelta * 0.45
        )
        
        let longitudeDelta = max(
            (cluster.bounds.maxLng - cluster.bounds.minLng) * 2.2,
            region.span.longitudeDelta * 0.45
        )
        
        withAnimation(.easeInOut(duration: 0.35)) {
            viewModel.selectedPostId = nil
            
            region = MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(
                    latitudeDelta: latitudeDelta,
                    longitudeDelta: longitudeDelta
                )
            )
        }
    }
    
    private func openPostDetails(_ post: MapMarkedPost) {
        // navCoordinator.navigate(to: .comment)
        print("Open post details:", post.id)
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
