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
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
    
    var body: some View {
        VStack {
            if displayLaunchScreen {
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 128, height: 128)
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .onAppear {
                        runAnimation()
                    }
            } else {
                AuthenticatedScreen()
                    .environmentObject(authVM)
            }
        }
    }
    
    private func runAnimation() {
        withAnimation(.easeInOut(duration: 0.5).delay(1)) {
            scale = 80
            opacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            displayLaunchScreen = false
        }
    }
}


#Preview {
    LaunchScreen()
        .environmentObject(AuthenticationViewModel())
}
