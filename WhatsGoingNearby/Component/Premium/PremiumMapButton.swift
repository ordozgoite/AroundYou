//
//  PremiumMapButton.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 09/05/26.
//

import SwiftUI

struct PremiumMapButton: View {
    
    let action: () -> Void
    
    private let goldGradient = LinearGradient(
        colors: [
            Color(red: 1.00, green: 0.88, blue: 0.48), // light champagne gold
            Color(red: 0.96, green: 0.70, blue: 0.22), // rich gold
            Color(red: 0.74, green: 0.45, blue: 0.08)  // deep gold
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    private let iconGradient = LinearGradient(
        colors: [
            .white,
            Color(red: 1.00, green: 0.96, blue: 0.82)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        Button {
            action()
        } label: {
            ZStack {
                Circle()
                    .fill(goldGradient)
                    .frame(width: 56, height: 56)
                    .overlay {
                        Circle()
                            .stroke(
                                Color.white.opacity(0.35),
                                lineWidth: 1
                            )
                    }
                    .overlay {
                        Circle()
                            .stroke(
                                Color(red: 0.65, green: 0.38, blue: 0.05).opacity(0.35),
                                lineWidth: 1
                            )
                            .padding(1)
                    }
                    .shadow(
                        color: Color(red: 0.95, green: 0.62, blue: 0.12).opacity(0.35),
                        radius: 10,
                        x: 0,
                        y: 4
                    )
                    .shadow(
                        color: .black.opacity(0.16),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                .white.opacity(0.38),
                                .white.opacity(0.0)
                            ],
                            center: .topLeading,
                            startRadius: 2,
                            endRadius: 38
                        )
                    )
                    .frame(width: 56, height: 56)
                    .allowsHitTesting(false)
                
                Image(systemName: "map.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(iconGradient)
                    .shadow(color: .black.opacity(0.18), radius: 1, x: 0, y: 1)
            }
            .frame(width: 64, height: 64)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Explore other places")
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()
        
        PremiumMapButton(action: {})
    }
}
