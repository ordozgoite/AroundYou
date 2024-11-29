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
        print("⚠️ updateEnv")
        print("userPreferences: \(userPreferences)")
        
        authVM.isUserDiscoverable = userPreferences.isDiscoverEnabled
        authVM.age = userPreferences.age ?? Constants.defaultUserAge
        authVM.gender = userPreferences.gender == nil ? .cisMale : Gender.from(description: userPreferences.gender!) ?? .cisMale
        authVM.interestGenders = userPreferences.interestGender == nil ? [] : Gender.from(array: userPreferences.interestGender!)
        authVM.minInterestAge = userPreferences.minInterestAge ?? Constants.defaultMinAgePreference
        authVM.maxInterestAge = userPreferences.maxInterestAge ?? Constants.defaultMaxAgePreference
        
        print("⚠️ Env Updated!")
    }
}

#Preview {
    DiscoverScreen()
        .environmentObject(AuthenticationViewModel())
}
