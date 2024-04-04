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
                Image("logo")
                    .resizable()
                    .frame(width: 128, height: 128)
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
