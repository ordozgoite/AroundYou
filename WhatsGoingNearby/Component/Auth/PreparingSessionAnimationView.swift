//
//  PreparingSessionAnimationView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 07/03/24.
//

import SwiftUI

struct PreparingSessionAnimationView: View {
    
    @Binding var isMissingUsername: Bool
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
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
                Task {
                    if authVM.authenticationState == .authenticated {
                        let token = try await authVM.getFirebaseToken()
                        isMissingUsername = await authVM.getUserInfo(token: token)
                    }
                }
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
}

//#Preview {
//    PreparingSessionAnimationView()
//}
