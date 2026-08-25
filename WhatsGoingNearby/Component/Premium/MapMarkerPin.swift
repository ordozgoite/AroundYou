//
//  MapMarkerPin.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 17/08/26.
//

import SwiftUI

/// Forma comum dos marcadores do Explore: círculo com o conteúdo e uma ponta central inferior
/// apontando para a coordenada.
///
/// A ponta é desenhada atrás do círculo, e sua base é o segmento em que as retas que partem da
/// ponta tangenciam o círculo. Nascendo dos pontos de tangência, as duas retas continuam o
/// contorno do círculo sem quina: a união lê como uma silhueta única de pin, e não como um círculo
/// apoiado numa haste.
///
/// A ponta encosta exatamente na base do frame, então quem posiciona o marcador deve ancorá-lo
/// pela borda inferior (`anchorPoint` com `y: 1`) para que ela caia sobre a coordenada.
///
/// O conteúdo preenche o círculo até o anel: em vez de ficar recuado dentro dele, termina no meio
/// do traço, que é desenhado por cima. Não sobra folga entre a foto e a borda, nem um segundo
/// círculo em volta dela.
struct MapMarkerPin<Content: View, Badge: View>: View {

    /// Quanto a ponta desce abaixo do círculo, em fração do diâmetro. Como toda a geometria da
    /// ponta deriva daqui, marcadores de tamanhos diferentes ficam proporcionais entre si.
    ///
    /// A tangência amarra altura e base: quanto mais baixa a ponta, mais estreita ela nasce. 0.22
    /// é o ponto de equilíbrio — a base fica em 72% do diâmetro, quase a mesma de antes, e o
    /// triângulo deixa de ser quase equilátero (fica cerca de duas vezes mais largo que alto).
    private static var tipHeightRatio: CGFloat { 0.22 }

    private static var ringWidth: CGFloat { 2.5 }

    let diameter: CGFloat
    let content: Content
    let badge: Badge

    // Opaco de propósito: o anel é traçado por cima do triângulo, e um branco translúcido se
    // somaria ao dele, deixando visível o arco de emenda entre as duas peças.
    private let ringColor = Color.white

    private var radius: CGFloat {
        diameter / 2
    }

    private var tipHeight: CGFloat {
        diameter * Self.tipHeightRatio
    }

    /// Distância do centro do círculo até a ponta.
    private var tipDistance: CGFloat {
        radius + tipHeight
    }

    /// Seno do ângulo de tangência, que dá tanto a meia-base quanto a profundidade dela.
    private var tangentRatio: CGFloat {
        radius / tipDistance
    }

    private var tipBaseWidth: CGFloat {
        2 * radius * sqrt(1 - tangentRatio * tangentRatio)
    }

    /// Distância entre o topo do círculo e a base do triângulo.
    private var tipBaseOffset: CGFloat {
        radius + radius * tangentRatio
    }

    init(
        diameter: CGFloat,
        @ViewBuilder badge: () -> Badge,
        @ViewBuilder content: (CGFloat) -> Content
    ) {
        self.diameter = diameter
        self.badge = badge()
        // Meio traço a menos: a borda do conteúdo cai sob o anel, então ele cobre a emenda sem
        // deixar aparecer nem folga nem a antialiasing do recorte.
        self.content = content(diameter - Self.ringWidth)
    }

    var body: some View {
        ZStack(alignment: .top) {
            MapMarkerTipShape()
                .fill(ringColor)
                .frame(
                    width: tipBaseWidth,
                    height: diameter + tipHeight - tipBaseOffset
                )
                .offset(y: tipBaseOffset)

            ZStack {
                // Base opaca: esconde a parte do triângulo que entra no círculo, mesmo quando o
                // conteúdo é translúcido.
                Circle()
                    .fill(ringColor)

                content
                    .clipShape(Circle())

                Circle()
                    .strokeBorder(ringColor, lineWidth: Self.ringWidth)
            }
            .frame(width: diameter, height: diameter)
            .overlay(alignment: .bottomTrailing) {
                badge
                    .offset(x: 5, y: -1)
            }
        }
        .frame(
            width: diameter,
            height: diameter + tipHeight,
            alignment: .top
        )
        .compositingGroup()
        .shadow(color: .black.opacity(0.18), radius: 6, x: 0, y: 3)
    }
}

extension MapMarkerPin where Badge == EmptyView {

    init(
        diameter: CGFloat,
        @ViewBuilder content: (CGFloat) -> Content
    ) {
        self.init(
            diameter: diameter,
            badge: { EmptyView() },
            content: content
        )
    }
}

struct MapMarkerTipShape: Shape {

    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()

        return path
    }
}

/// Selo circular escuro sobreposto ao marcador, usado para o contador do cluster e para o aviso de
/// localização aproximada.
struct MapMarkerBadge<Content: View>: View {

    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let content: Content

    init(
        horizontalPadding: CGFloat = 6,
        verticalPadding: CGFloat = 3,
        @ViewBuilder content: () -> Content
    ) {
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        self.content = content()
    }

    var body: some View {
        content
            .foregroundStyle(.white)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(.black.opacity(0.8))
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(.white.opacity(0.95), lineWidth: 1)
            }
    }
}
