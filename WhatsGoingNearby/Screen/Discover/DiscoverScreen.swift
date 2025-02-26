//
//  DiscoverScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 25/10/24.
//

import SwiftUI

struct DiscoverScreen: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var discoverVM = DiscoverViewModel()
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var socket: SocketService
    
    var body: some View {
        ZStack {
            if discoverVM.isLoading {
                ProgressView()
            } else if !authVM.isUserDiscoverable {
                ActivateDiscoverView(isLoading: $discoverVM.isActivatingDiscover) {
                    Task {
                        try await activateDiscover()
                    }
                }
            } else {
                DiscoverView(discoverVM: discoverVM, locationManager: locationManager, socket: socket)
            }
        }
        .onAppear {
            Task {
                let token = try await authVM.getFirebaseToken()
                if let userPreferences = await discoverVM.verifyUserDiscoverability(token: token) {
                    updateEnv(withPreferences: userPreferences)
                }
            }
        }
        .sheet(isPresented: $discoverVM.isPreferencesViewDisplayed) {
            DiscoverPreferencesView(discoverVM: discoverVM, locationManager: locationManager)
                .environmentObject(authVM)
        }
    }
    
    //MARK: - Private Methods
    
    private func activateDiscover() async throws {
        let token = try await authVM.getFirebaseToken()
        do {
            try await discoverVM.activateUserDiscoverability(token: token)
            authVM.isUserDiscoverable = true
        } catch {
            print("❌ Error trying to activate Discover.")
        }
    }
    
    private func updateEnv(withPreferences userPreferences: VerifyUserDiscoverabilityResponse) {
        authVM.isUserDiscoverable = userPreferences.isDiscoverEnabled
        authVM.age = userPreferences.age ?? Constants.DEFAULT_USER_AGE
        authVM.gender = userPreferences.gender == nil ? .cisMale : Gender.from(description: userPreferences.gender!) ?? .cisMale
        authVM.interestGenders = userPreferences.interestGender == nil ? [] : Gender.from(array: userPreferences.interestGender!)
        authVM.minInterestAge = userPreferences.minInterestAge ?? Constants.DEFAULT_MIN_AGE_PREFERENCE
        authVM.maxInterestAge = userPreferences.maxInterestAge ?? Constants.DEFAULT_MAX_AGE_PREFERENCE
        authVM.isDiscoverNotificationsEnabled = userPreferences.isDiscoverNotificationsEnabled
    }
}

#Preview {
//    DiscoverScreen()
//        .environmentObject(AuthenticationViewModel())
}
