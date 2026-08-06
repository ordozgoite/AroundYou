//
//  ExploreMapHintBubble.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 06/08/26.
//

import SwiftUI

/// Small hint balloon displayed to the left of `PremiumMapButton` when there is
/// nothing active around the user, suggesting the map as the next action.
struct ExploreMapHintBubble: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hasAppeared = false

    private let cornerRadius: CGFloat = 16
    private let tailWidth: CGFloat = 9
    private let tailHeight: CGFloat = 18

    private var shape: ExploreMapHintBubbleShape {
        ExploreMapHintBubbleShape(
            cornerRadius: cornerRadius,
            tailWidth: tailWidth,
            tailHeight: tailHeight
        )
    }

    var body: some View {
        HStack(spacing: 6) {
            Text("Explore map")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            Text(verbatim: "✨")
                .font(.subheadline)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .padding(.trailing, tailWidth)
        .background {
            shape
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
        }
        .overlay {
            shape
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        }
        .opacity(hasAppeared ? 1 : 0)
        .scaleEffect(hasAppeared ? 1 : 0.95, anchor: .trailing)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion else {
                hasAppeared = true
                return
            }

            withAnimation(.easeOut(duration: 0.32)) {
                hasAppeared = true
            }
        }
    }
}

//MARK: - Shape

private struct ExploreMapHintBubbleShape: Shape {

    let cornerRadius: CGFloat
    let tailWidth: CGFloat
    let tailHeight: CGFloat

    func path(in rect: CGRect) -> Path {
        let bodyRect = CGRect(
            x: rect.minX,
            y: rect.minY,
            width: max(rect.width - tailWidth, 0),
            height: rect.height
        )

        let body = Path(
            roundedRect: bodyRect,
            cornerSize: CGSize(width: cornerRadius, height: cornerRadius),
            style: .continuous
        )

        // Soft tail pointing to the map button, on the trailing edge.
        let midY = bodyRect.midY
        let baseX = bodyRect.maxX - 2

        var tail = Path()
        tail.move(to: CGPoint(x: baseX, y: midY - tailHeight / 2))
        tail.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: midY),
            control: CGPoint(x: baseX + tailWidth * 0.45, y: midY - tailHeight * 0.26)
        )
        tail.addQuadCurve(
            to: CGPoint(x: baseX, y: midY + tailHeight / 2),
            control: CGPoint(x: baseX + tailWidth * 0.45, y: midY + tailHeight * 0.26)
        )
        tail.closeSubpath()

        // Merged so body and tail share a single outline, with no seam.
        return Path(body.cgPath.union(tail.cgPath))
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()

        HStack(spacing: 4) {
            ExploreMapHintBubble()

            PremiumMapButton(isHighlighted: true, action: {})
        }
    }
}
