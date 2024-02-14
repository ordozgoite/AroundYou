//
//  PreparingSessionScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 14/02/24.
//

import SwiftUI

struct PreparingSessionScreen: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    
    var body: some View {
        VStack {
            if authVM.isUserInfoFetched {
                MainTabView()
                    .environmentObject(authVM)
            } else {
                ProgressView()
                    .onAppear {
                        Task {
                            if authVM.authenticationState == .authenticated {
                                print("⚠️ Começou a carregar a sessão")
                                let token = try await authVM.getFirebaseToken()
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
}

#Preview {
    PreparingSessionScreen()
}
