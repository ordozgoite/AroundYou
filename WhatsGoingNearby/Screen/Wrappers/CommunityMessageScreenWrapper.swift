//
//  CommunityMessageScreenWrapper.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 23/05/25.
//

import SwiftUI

struct CommunityMessageScreenWrapper: View {
    let communityId: String
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var socket: SocketService
    @Environment(\.presentationMode) var presentationMode
    
    @State private var community: FormattedCommunity? = nil
    @State private var isLoading: Bool = false
    @State private var overlayError: (Bool, LocalizedStringKey) = (false, "")
    
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView()
            } else {
                if let community = community {
                    NavigationView {
                        CommunityMessageScreen(
                            community: community,
                            isViewDisplayed: .constant(true),
                            locationManager: locationManager,
                            socket: socket,
                            refreshCommunities: {}
                        )
                        .navigationBarItems(leading: Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }, label: {
                            Image(systemName: "xmark")
                        }))
                    }
                }
            }
            
            AYErrorAlert(message: overlayError.1, isErrorAlertPresented: $overlayError.0)
        }
        .onAppear {
            Task {
                try await attemptCommunityInfoFetch()
            }
        }
    }
}

// MARK: - Private Methods

extension CommunityMessageScreenWrapper {
    private func attemptCommunityInfoFetch() async throws {
        do {
            try await handleCommunityInfoFetch()
        } catch {
            overlayError = (true, "Error trying to fetch community info.")
        }
    }
    
    private func handleCommunityInfoFetch() async throws {
        let token = try await authVM.getFirebaseToken()
        let currentLocation = try getCurrentLocation()
        await getCommunityInfo(location: currentLocation, token: token)
    }
    
    private func getCurrentLocation() throws -> Location {
        locationManager.requestLocation()
        if let location = locationManager.location {
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            return Location(latitude: latitude, longitude: longitude)
        } else {
            throw LocationError.unableToGetCurrentLocation
        }
    }
    
    private func getCommunityInfo(location: Location, token: String) async {
        isLoading = true
        defer { isLoading = false }
        
        let result = await AYServices.shared.getCommunity(communityId: self.communityId, location: location, token: token)
        
        handleGetCommuntyResult(result)
    }
    
    private func handleGetCommuntyResult(_ result: Result<FormattedCommunity, RequestError>) {
        switch result {
        case .success(let community):
            self.community = community
        case .failure:
            overlayError = (true, "Error trying to fetch community info.")
        }
    }
}

#Preview {
    CommunityMessageScreenWrapper(communityId: UUID().uuidString, locationManager: LocationManager(), socket: SocketService())
}
