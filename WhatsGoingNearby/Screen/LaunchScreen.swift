//
//  LaunchScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 16/02/24.
//

import SwiftUI

struct LaunchScreen: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @State private var displayLaunchScreen = true
    
    var body: some View {
        VStack {
            if displayLaunchScreen {
                Image(systemName: "location.circle")
                    .resizable()
                    .frame(width: 128, height: 128)
                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.red, .blue]), startPoint: .topLeading, endPoint: .bottomTrailing))
            } else {
                AuthenticatedScreen()
                    .environmentObject(authVM)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                displayLaunchScreen = false
            }
        }
    }
}

#Preview {
    LaunchScreen()
        .environmentObject(AuthenticationViewModel())
}
