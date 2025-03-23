//
//  UrgentScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 21/03/25.
//

import SwiftUI

struct UrgentScreen: View {
    var body: some View {
        NavigationStack {
            VStack {
                Warning()
                
                AlertButton()
            }
            .padding()
        }
    }
    
    // MARK: - Warning
    
    @ViewBuilder
    private func Warning() -> some View {
        VStack {
            Image(systemName: "light.beacon.max")
                .resizable()
                .scaledToFit()
                .frame(height: 128)
                .foregroundStyle(.gray)
            
            Text("This functionality should only be used in case of a real emergency. Your location will be automatically shared with the police.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.gray)
        }
        .frame(maxHeight: .infinity, alignment: .center)
    }
    
    // MARK: - Alert Button
    
    @ViewBuilder
    private func AlertButton() -> some View {
        VStack(spacing: 0) {
            AYButton(title: "Alert Police") {
                // TODO: Integrar com a polícia
            }
            .disabled(true)
            
            Text("Under Construction.")
                .foregroundStyle(.gray)
                .font(.caption)
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
    }
}

#Preview {
    UrgentScreen()
}
