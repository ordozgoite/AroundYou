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
    @State private var minAnimDisplayTimeReached = false
    
    var body: some View {
        VStack {
            if authVM.isUserInfoFetched && minAnimDisplayTimeReached {
                MainTabView()
                    .environmentObject(authVM)
            } else {
                PreparingSessionAnimation()
                    .onAppear {
                        Task {
                            if authVM.authenticationState == .authenticated {
                                print("⚠️ Começou a carregar a sessão")
                                let token = try await authVM.getFirebaseToken()
                                print("🔑 USER TOKEN: \(token)")
                                if authVM.flow == .login {
                                    await authVM.getUserInfo(token: token)
                                } else {
                                    await authVM.postNewUser(token: token)
                                }
                            }
                        }
                    }
            }
        }
    }
    
    //MARK: - Loading Animation
    
    @ViewBuilder
    private func PreparingSessionAnimation() -> some View {
        VStack {
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
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                minAnimDisplayTimeReached = true
            }
        }
    }
}

#Preview {
    PreparingSessionScreen()
        .environmentObject(AuthenticationViewModel())
}
