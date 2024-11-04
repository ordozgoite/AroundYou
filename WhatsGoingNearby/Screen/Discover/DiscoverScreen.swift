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
            } else if !discoverVM.isDiscoverable {
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
                await discoverVM.verifyUserDiscoverability(token: token)
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
        await discoverVM.activateUserDiscoverability(token: token)
    }
}

#Preview {
    DiscoverScreen()
        .environmentObject(AuthenticationViewModel())
}
