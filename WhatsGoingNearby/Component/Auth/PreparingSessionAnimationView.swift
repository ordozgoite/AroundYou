//
//  PreparingSessionAnimationView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 07/03/24.
//

import SwiftUI

struct PreparingSessionAnimationView: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @Environment(\.colorScheme) var colorScheme
    
    @State private var isRetryButtonDisplayed: Bool = false
    @State private var refreshObserver = NotificationCenter.default
        .publisher(for: .goToUsernameScreen)
    
    var body: some View {
        NavigationStack {
            VStack {
                if authVM.isGettingUserInfo {
                    LoadAnimation()
                } else if isRetryButtonDisplayed {
                    Retry()
                }
            }
            .onAppear {
                Task {
                    try await fetchUserInfo()
                }
            }
            .onReceive(refreshObserver) { _ in
                self.isRetryButtonDisplayed = true
            }
            .toolbar {
                ToolbarItem {
                    Button {
                        authVM.signOut()
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundStyle(.gray)
                    }
                }
            }
        }
    }
    
    // MARK: - Retry Button
    
    @ViewBuilder
    private func Retry() -> some View {
        VStack {
            Text("Error trying to get user info.")
                .foregroundStyle(.gray)
                .bold()
            
            Button("Retry") {
                Task {
                    self.isRetryButtonDisplayed = false
                    try await fetchUserInfo()
                }
            }
        }
    }
    
    // MARK: - Load Animation
    
    @ViewBuilder
    private func LoadAnimation() -> some View {
        if colorScheme == .dark {
            LottieView(name: "map", loopMode: .loop)
                .scaleEffect(0.5)
                .frame(width: screenWidth * 0.5, height: screenHeight * 0.5)
                .colorInvert()
        } else {
            LottieView(name: "map", loopMode: .loop)
                .scaleEffect(0.5)
                .frame(width: screenWidth * 0.5, height: screenHeight * 0.5)
        }
        
        Text("We use your location to know what's going on around you.")
            .multilineTextAlignment(.center)
            .foregroundStyle(.gray)
            .fontWeight(.semibold)
    }
}

// MARK: - Private Methods

extension PreparingSessionAnimationView {
    private func fetchUserInfo() async throws {
        if authVM.authenticationState == .authenticated {
            let token = try await authVM.getFirebaseToken()
            await authVM.getUserInfo(token: token)
        }
    }
}

//#Preview {
//    PreparingSessionAnimationView()
//}
