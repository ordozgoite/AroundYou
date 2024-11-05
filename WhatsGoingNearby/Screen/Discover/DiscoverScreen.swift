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
                DiscoverView(discoverVM: discoverVM)
            }
        }
        .onAppear {
            Task {
                let token = try await authVM.getFirebaseToken()
                if let userPreferences = await discoverVM.verifyUserDiscoverability(token: token) {
                    updateEnv(withPreferences: userPreferences)
                    print("👻👻👻👻👻")
                }
            }
        }
        .sheet(isPresented: $discoverVM.isPreferencesViewDisplayed) {
            DiscoverPreferencesView(discoverVM: discoverVM)
                .environmentObject(authVM)
        }
    }
    
    //MARK: - Private Methods
    
    private func activateDiscover() async throws {
        let token = try await authVM.getFirebaseToken()
        await discoverVM.activateUserDiscoverability(token: token) { isDiscoverable in
            authVM.isUserDiscoverable = isDiscoverable
        }
    }
    
    private func updateEnv(withPreferences userPreferences: VerifyUserDiscoverabilityResponse) {
        authVM.isUserDiscoverable = userPreferences.isDiscoverEnabled
        authVM.age = userPreferences.age ?? 18
//        authVM.gender = userPreferences.selectedGender ?? .male
//        authVM.interestGender = userPreferences.selectedInterestGender
        authVM.minInterestAge = userPreferences.minInterestAge ?? 25
        authVM.maxInterestAge = userPreferences.maxInterestAge ?? 40
    }
}

#Preview {
    DiscoverScreen()
        .environmentObject(AuthenticationViewModel())
}
