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
    @State private var refreshObserver = NotificationCenter.default
        .publisher(for: .goToUsernameScreen)
    
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
                    PreparingSessionAnimationView()
                        .environmentObject(authVM)
                }
            }
        }
        .onAppear {
            prepareToGetNewUserInfo()
        }
        .onReceive(refreshObserver) { _ in
            goToUserNameScreen()
        }
    }
    
    // MARK: - Pivate Methods
    
    private func prepareToGetNewUserInfo() {
        print("🌎 prepareToGetNewUserInfo")
        authVM.isUserInfoFetched = false
    }
    
    private func goToUserNameScreen() {
        self.isMissingUsername = true
    }
}

#Preview {
    PreparingSessionScreen()
        .environmentObject(AuthenticationViewModel())
}
