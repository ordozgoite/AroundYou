//
//  ExploreMapCard.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 14/08/26.
//

import SwiftUI

/// Card presented as the first item of the feed, inviting the user to browse
/// publications beyond the current location through the explore map.
struct ExploreMapCard: View {

    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private let cornerRadius: CGFloat = 22
    private let badgeDiameter: CGFloat = 52

    private let gold = Color(red: 0.95, green: 0.72, blue: 0.26)
    private let deepGold = Color(red: 0.80, green: 0.52, blue: 0.10)
    private let champagne = Color(red: 1.00, green: 0.92, blue: 0.68)

    /// Only the gold accents are fixed: surfaces and texts follow the system
    /// appearance like the rest of the feed.
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: colorScheme == .dark
            ? [
                Color(red: 0.09, green: 0.09, blue: 0.10),
                Color(red: 0.04, green: 0.04, blue: 0.05)
            ]
            : [
                Color(uiColor: .systemBackground),
                Color(uiColor: .secondarySystemBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Over a light surface the gold halo turns into a yellow stain, so it is
    /// dialed back and a neutral shadow grounds the card instead.
    private var glowOpacity: Double {
        colorScheme == .dark ? 0.16 : 0.08
    }

    private var ambientShadowColor: Color {
        colorScheme == .dark ? .clear : .black.opacity(0.10)
    }

    private let goldGradient = LinearGradient(
        colors: [
            Color(red: 0.99, green: 0.82, blue: 0.38),
            Color(red: 0.93, green: 0.65, blue: 0.16),
            Color(red: 0.80, green: 0.52, blue: 0.10)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 14) {
                CompassBadge()

                Texts()
            }

            HStack {
                Spacer(minLength: 0)

                ExploreButton()
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 160, alignment: .topLeading)
        .background { Background() }
        .overlay { Border() }
        .shadow(color: gold.opacity(glowOpacity), radius: 12, x: 0, y: 0)
        .shadow(color: ambientShadowColor, radius: 10, x: 0, y: 4)
        .contentShape(cardShape)
        .onTapGesture { openExploreMap() }
        .accessibilityElement(children: .combine)
    }

    //MARK: - Background

    @ViewBuilder
    private func Background() -> some View {
        ZStack(alignment: .trailing) {
            backgroundGradient

            DecorativeMap()
        }
        // Isolates the map blending, so it only mixes with the card background.
        .compositingGroup()
        .clipShape(cardShape)
    }

    //MARK: - Decorative Map

    @ViewBuilder
    private func DecorativeMap() -> some View {
        GeometryReader { proxy in
            let artworkWidth = proxy.size.width * 0.62

            Group {
                if colorScheme == .dark {
                    Artwork(
                        width: artworkWidth,
                        height: proxy.size.height
                    )
                    .opacity(0.9)
                    .blendMode(.screen)
                } else {
                    Artwork(
                        width: artworkWidth,
                        height: proxy.size.height
                    )
                    .opacity(0.70)
                }
            }
            .mask(
                LinearGradient(
                    colors: [
                        .clear,
                        .black.opacity(0.45),
                        .black
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(
                width: proxy.size.width,
                height: proxy.size.height,
                alignment: .trailing
            )
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func Artwork(width: CGFloat, height: CGFloat) -> some View {
        Image(colorScheme == .dark
              ? "explore-button-icon-dark"
              : "explore-button-icon-light")
            .resizable()
            .scaledToFill()
            .frame(width: width, height: height)
            .clipped()
    }

    //MARK: - Compass Badge

    @ViewBuilder
    private func CompassBadge() -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        gold.opacity(colorScheme == .dark ? 0.28 : 0.22),
                        gold.opacity(colorScheme == .dark ? 0.06 : 0.08)
                    ],
                    center: .center,
                    startRadius: 2,
                    endRadius: badgeDiameter * 0.55
                )
            )
            .frame(width: badgeDiameter, height: badgeDiameter)
            .overlay {
                Circle()
                    .strokeBorder(gold.opacity(colorScheme == .dark ? 0.55 : 0.70), lineWidth: 1)
            }
            .overlay {
                Image(systemName: "safari")
                    .font(.system(size: 26, weight: .regular))
                    // A champagne tip reads well over the dark card, but washes
                    // out over a light one, where a deeper gold is used instead.
                    .foregroundStyle(
                        LinearGradient(
                            colors: colorScheme == .dark
                            ? [champagne, gold]
                            : [gold, deepGold],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .accessibilityHidden(true)
    }

    //MARK: - Texts

    @ViewBuilder
    private func Texts() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Explore the city")
                .font(.system(size: 21, weight: .bold))
                .foregroundStyle(.primary)

            Text("See posts beyond your current location.")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    //MARK: - Explore Button

    @ViewBuilder
    private func ExploreButton() -> some View {
        Button {
            openExploreMap()
        } label: {
            HStack(spacing: 6) {
                Text("Explore")
                    .font(.system(size: 16, weight: .semibold))

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .frame(height: 46)
            .background {
                Capsule()
                    .fill(goldGradient)
                    .shadow(
                        color: gold.opacity(colorScheme == .dark ? 0.35 : 0.22),
                        radius: 10,
                        x: 0,
                        y: 4
                    )
            }
        }
        .buttonStyle(.plain)
    }

    //MARK: - Border

    @ViewBuilder
    private func Border() -> some View {
        cardShape
            .strokeBorder(
                LinearGradient(
                    colors: [
                        gold.opacity(0.75),
                        gold.opacity(0.25)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
            .allowsHitTesting(false)
    }

    //MARK: - Private Method

    private func openExploreMap() {
        hapticFeedback(style: .soft)
        action()
    }
}

#Preview("Dark") {
    ZStack {
        Color(.systemBackground)
            .ignoresSafeArea()

        ExploreMapCard(action: {})
            .padding()
    }
    .preferredColorScheme(.dark)
}

#Preview("Light") {
    ZStack {
        Color(.systemBackground)
            .ignoresSafeArea()

        ExploreMapCard(action: {})
            .padding()
    }
    .preferredColorScheme(.light)
}
