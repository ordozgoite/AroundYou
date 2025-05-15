//
//  LaunchScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 16/02/24.
//

import SwiftUI

struct LaunchScreen: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
    @State private var hideLogo = false
    
    var body: some View {
        ZStack {
            // Tela principal já sendo carregada no fundo
            AuthenticatedScreen()
                .environmentObject(authVM)
            
            // Animação da logo por cima
            if !hideLogo {
                Color(.systemBackground) // Evita mostrar partes da tela no início
                    .ignoresSafeArea()
                
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 128, height: 128)
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .onAppear {
                        runAnimation()
                    }
            }
        }
    }
    
    private func runAnimation() {
        withAnimation(.easeInOut(duration: 0.5).delay(1)) {
            scale = 150
            opacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            hideLogo = true
        }
    }
}



#Preview {
    LaunchScreen()
        .environmentObject(AuthenticationViewModel())
}
