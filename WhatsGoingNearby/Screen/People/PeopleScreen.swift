//
//  DiscoverScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 25/10/24.
//

import SwiftUI

struct PeopleScreen: View {
    @EnvironmentObject var authVM: AuthenticationViewModel
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var socket: SocketService
    @ObservedObject var peopleVM: PeopleViewModel
    
    var body: some View {
        ZStack {
            if peopleVM.isLoading || !authVM.isUserDiscoverable {
                NotDiscoveringScreen(peopleVM: peopleVM)
            } else {
                DiscoverView(discoverVM: peopleVM)
            }
            
            AYErrorAlert(message: peopleVM.overlayError.1 , isErrorAlertPresented: $peopleVM.overlayError.0)
        }
        .onAppear {
            Task {
                let token = try await authVM.getFirebaseToken()
                if let userPreferences = await peopleVM.verifyUserDiscoverability(token: token) {
                    updateEnv(withPreferences: userPreferences)
                }
            }
        }
        .sheet(isPresented: $peopleVM.isPreferencesViewDisplayed) {
            DiscoverPreferencesView(discoverVM: peopleVM)
                .environmentObject(authVM)
        }
    }
    
    //MARK: - Private Methods
    
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
