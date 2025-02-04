//
//  PreparingSessionScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 14/02/24.
//

import SwiftUI

struct PreparingSessionScreen: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @Environment(\.colorScheme) var colorScheme
    
    @State private var hasCompletedOnboarding = LocalState.hasCompletedOnboarding
    @State private var isMissingUsername: Bool = false
    
    var body: some View {
        VStack {
            if authVM.isUserInfoFetched {
                if !hasCompletedOnboarding {
                    OnBoardingScreen(hasCompletedOnboarding: $hasCompletedOnboarding)
                } else {
                    MainTabView()
                        .environmentObject(authVM)
                }
            } else {
                if isMissingUsername {
                    UsernameScreen()
                        .environmentObject(authVM)
                } else {
                    PreparingSessionAnimationView(isMissingUsername: $isMissingUsername)
                        .environmentObject(authVM)
                }
            }
        }
        .onAppear {
            prepareToGetNewUserInfo()
        }
    }
    
    // MARK: - Pivate Methods
    
    private func prepareToGetNewUserInfo() {
        print("🌎 prepareToGetNewUserInfo")
        authVM.isUserInfoFetched = false
    }
}

#Preview {
    PreparingSessionScreen()
        .environmentObject(AuthenticationViewModel())
}
