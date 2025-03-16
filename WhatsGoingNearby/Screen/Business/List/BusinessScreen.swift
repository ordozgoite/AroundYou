//
//  BusinessScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 26/02/25.
//

import SwiftUI

struct BusinessScreen: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var businessVM = BusinessViewModel()
    @ObservedObject var locationManager: LocationManager
    
    var body: some View {
        NavigationStack {
            VStack {
                if businessVM.isLoading {
                    LoadingView()
                } else if businessVM.businesses.isEmpty {
                    EmptyBusinessView()
                } else {
                    BusinessList()
                }
            }
            .onAppear {
                Task {
                    try await getBusinesses()
                }
            }
            .navigationTitle("Business")
            .toolbar {
                NavigationLink(destination: PublishBusinessScreen(locationManager: locationManager).environmentObject(authVM)) {
                    Image(systemName: "plus")
                }
            }
        }
    }
    
    //MARK: - Loading
    
    @ViewBuilder
    private func LoadingView() -> some View {
        VStack {
            AYProgressView()
            
            Text("Looking around you...")
                .foregroundStyle(.gray)
                .fontWeight(.semibold)
        }
    }
    
    // MARK: - Business List
    
    @ViewBuilder
    private func BusinessList() -> some View {
        List {
            ForEach(businessVM.businesses) { business in
                BusinessShowcaseView(showcase: business)
                    .environmentObject(authVM)
            }
        }
    }
}

// MARK: - Private Methods

extension BusinessScreen {
    private func getBusinesses() async throws {
        locationManager.requestLocation()
        if let location = locationManager.location {
            let token = try await authVM.getFirebaseToken()
            
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            let currentLocation = Location(latitude: latitude, longitude: longitude)
            
            await businessVM.getBusinesses(location: currentLocation, token: token)
        }
    }
}

#Preview {
    BusinessScreen(locationManager: LocationManager())
}
