//
//  DiscoverScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 25/10/24.
//

import SwiftUI

struct DiscoverScreen: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var discoveryVM = DiscoverViewModel()
    
    var body: some View {
        ZStack {
            if discoveryVM.isLoading {
                ProgressView()
            } else if !discoveryVM.isDiscoverable {
                ActivateDiscoverView()
            } else {
                // LikingView
            }
        }
        .onAppear {
            Task {
                let token = try await authVM.getFirebaseToken()
                await discoveryVM.verifyUserDiscoverability(token: token)
            }
        }
    }
}

#Preview {
    DiscoverScreen()
}
