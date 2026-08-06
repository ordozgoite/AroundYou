//
//  PremiumMapButton.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 09/05/26.
//

import SwiftUI

struct PremiumMapButton: View {

    /// When `true`, the button gets a slightly stronger halo and an extremely
    /// discreet breathing animation, signaling it as the recommended next action.
    var isHighlighted: Bool = false
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isBreathing = false

    private let diameter: CGFloat = 60

    private let goldGradient = LinearGradient(
        colors: [
            Color(red: 1.00, green: 0.93, blue: 0.66), // champagne highlight
            Color(red: 0.99, green: 0.82, blue: 0.38), // light gold
            Color(red: 0.95, green: 0.68, blue: 0.19), // rich gold
            Color(red: 0.84, green: 0.55, blue: 0.12), // deep gold
            Color(red: 0.72, green: 0.44, blue: 0.08)  // bronze
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

    private var glowOpacity: Double {
        isBreathing ? 0.90 : (isHighlighted ? 0.65 : 0.50)
    }

    private var glowScale: CGFloat {
        isBreathing ? 1.06 : 1.0
    }

    var body: some View {
        Button {
            action()
        } label: {
            ZStack {
                SoftGlow()

                Circle()
                    .fill(goldGradient)
                    .frame(width: diameter, height: diameter)
                    .overlay { TopHighlight() }
                    .overlay { Rim() }
                    .clipShape(Circle())
                    .shadow(
                        color: Color(red: 0.95, green: 0.62, blue: 0.12).opacity(0.30),
                        radius: 16,
                        x: 0,
                        y: 8
                    )
                    .shadow(
                        color: .black.opacity(0.14),
                        radius: 14,
                        x: 0,
                        y: 7
                    )

                Image(systemName: "map.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(iconGradient)
                    .shadow(color: .black.opacity(0.18), radius: 1, x: 0, y: 1)
            }
            .frame(width: diameter + 8, height: diameter + 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Explore other places")
        .onAppear { updateBreathing() }
        .onChange(of: isHighlighted) { _ in updateBreathing() }
    }

    //MARK: - Soft Glow

    @ViewBuilder
    private func SoftGlow() -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color(red: 1.00, green: 0.78, blue: 0.30).opacity(0.55),
                        Color(red: 1.00, green: 0.72, blue: 0.20).opacity(0.0)
                    ],
                    center: .center,
                    startRadius: diameter * 0.34,
                    endRadius: diameter * 0.74
                )
            )
            .frame(width: diameter * 1.5, height: diameter * 1.5)
            .blur(radius: 6)
            .opacity(glowOpacity)
            .scaleEffect(glowScale)
            .allowsHitTesting(false)
    }

    //MARK: - Top Highlight

    @ViewBuilder
    private func TopHighlight() -> some View {
        ZStack {
            // Broad sheen coming from the top-leading edge, giving volume.
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .white.opacity(0.42),
                            .white.opacity(0.0)
                        ],
                        center: .topLeading,
                        startRadius: 2,
                        endRadius: diameter * 0.72
                    )
                )

            // Specular highlight on the upper part of the sphere.
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.70),
                            .white.opacity(0.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: diameter * 0.60, height: diameter * 0.32)
                .offset(y: -diameter * 0.25)
                .blur(radius: 4)

            // Warm bounce light at the bottom, so the sphere doesn't look flat.
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.00, green: 0.86, blue: 0.52).opacity(0.0),
                            Color(red: 1.00, green: 0.86, blue: 0.52).opacity(0.32)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: diameter * 0.72, height: diameter * 0.26)
                .offset(y: diameter * 0.28)
                .blur(radius: 6)
        }
        .allowsHitTesting(false)
    }

    //MARK: - Rim

    @ViewBuilder
    private func Rim() -> some View {
        ZStack {
            // Barely perceptible light border.
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.50),
                            .white.opacity(0.08)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )

            // Inner darker gold line, adds depth to the edge.
            Circle()
                .strokeBorder(
                    Color(red: 0.65, green: 0.38, blue: 0.05).opacity(0.28),
                    lineWidth: 1
                )
                .padding(1)
        }
        .allowsHitTesting(false)
    }

    //MARK: - Private Method

    private func updateBreathing() {
        guard isHighlighted, !reduceMotion else {
            withAnimation(.easeOut(duration: 0.4)) {
                isBreathing = false
            }
            return
        }

        withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
            isBreathing = true
        }
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()

        VStack(spacing: 48) {
            PremiumMapButton(action: {})

            PremiumMapButton(isHighlighted: true, action: {})
        }
    }
}
