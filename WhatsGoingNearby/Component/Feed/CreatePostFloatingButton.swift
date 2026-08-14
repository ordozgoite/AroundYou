//
//  CreatePostFloatingButton.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 14/08/26.
//

import SwiftUI

/// Circular floating action button used as the only entry point for creating a
/// publication in the feed.
struct CreatePostFloatingButton: View {

    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private let diameter: CGFloat = 60

    /// Over a light background the blue halo reads much stronger, so it is
    /// toned down instead of being removed.
    private var glowColor: Color {
        Color.blue.opacity(colorScheme == .dark ? 0.35 : 0.20)
    }

    private var ambientShadowColor: Color {
        Color.black.opacity(colorScheme == .dark ? 0.18 : 0.12)
    }

    private let blueGradient = LinearGradient(
        colors: [
            Color(red: 0.24, green: 0.56, blue: 1.00),
            Color(red: 0.04, green: 0.42, blue: 0.98)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        Button {
            hapticFeedback(style: .soft)
            action()
        } label: {
            ZStack {
                Circle()
                    .fill(blueGradient)
                    .frame(width: diameter, height: diameter)
                    // Discreet blue glow, plus a neutral shadow so the button
                    // keeps floating over any content.
                    .shadow(color: glowColor, radius: colorScheme == .dark ? 14 : 10, x: 0, y: 6)
                    .shadow(color: ambientShadowColor, radius: 8, x: 0, y: 4)

                Image(systemName: "plus")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: diameter, height: diameter)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Create new post")
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()

        CreatePostFloatingButton(action: {})
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(.trailing, 20)
            .padding(.bottom, 16)
    }
}
