//
//  MessageView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 27/03/24.
//

import SwiftUI

/// Métricas compartilhadas pelas bolhas de mensagem (chat e comunidade).
enum ChatBubbleLayout {
    /// Margem entre a lista de mensagens e as bordas da tela.
    static let screenMargin: CGFloat = 12
    /// Fração da largura disponível que uma bolha pode ocupar.
    static let maxWidthRatio: CGFloat = 0.78
    static let horizontalPadding: CGFloat = 14
    static let verticalPadding: CGFloat = 9
    /// Espaçamento entre mensagens consecutivas do mesmo remetente.
    static let groupedSpacing: CGFloat = 3
    /// Espaçamento entre a última mensagem de um grupo e a próxima.
    static let groupSpacing: CGFloat = 10
    static let cornerRadius: CGFloat = 20
    /// Raio dos cantos internos de um grupo — é ele que "cola" as bolhas.
    static let groupedCornerRadius: CGFloat = 7
    /// Gutter usado enquanto a largura real do container não é conhecida.
    static let fallbackGutter: CGFloat = 64
    static let timeFont: Font = .system(size: 10.5)

    /// Espaço reservado do lado oposto à bolha. É ele que limita a largura máxima:
    /// a bolha recebe `largura disponível - gutter` como proposta e quebra linha ali,
    /// mas continua se ajustando ao conteúdo quando a mensagem é curta.
    static func gutter(forAvailableWidth width: CGFloat?) -> CGFloat {
        guard let width, width > 0 else { return fallbackGutter }
        return width * (1 - maxWidthRatio)
    }

    static func bottomSpacing(isLastInGroup: Bool) -> CGFloat {
        isLastInGroup ? groupSpacing : groupedSpacing
    }
}

private struct ChatAvailableWidthKey: EnvironmentKey {
    static let defaultValue: CGFloat? = nil
}

extension EnvironmentValues {
    /// Largura útil da lista de mensagens, já descontadas as margens laterais.
    /// `nil` significa "ainda não medida" — nesse caso as bolhas usam o gutter fixo.
    var chatAvailableWidth: CGFloat? {
        get { self[ChatAvailableWidthKey.self] }
        set { self[ChatAvailableWidthKey.self] = newValue }
    }
}

/// Retângulo com raio independente por canto.
///
/// `UnevenRoundedRectangle` resolveria isso, mas só existe a partir do iOS 17 e o app
/// ainda suporta o 16.4.
struct BubbleShape: Shape {

    var topLeading: CGFloat
    var topTrailing: CGFloat
    var bottomLeading: CGFloat
    var bottomTrailing: CGFloat

    func path(in rect: CGRect) -> Path {
        let limit = min(rect.width, rect.height) / 2
        let tl = min(topLeading, limit)
        let tr = min(topTrailing, limit)
        let bl = min(bottomLeading, limit)
        let br = min(bottomTrailing, limit)

        var path = Path()
        path.move(to: CGPoint(x: rect.minX + tl, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - tr, y: rect.minY))
        path.addArc(center: CGPoint(x: rect.maxX - tr, y: rect.minY + tr), radius: tr,
                    startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - br))
        path.addArc(center: CGPoint(x: rect.maxX - br, y: rect.maxY - br), radius: br,
                    startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX + bl, y: rect.maxY))
        path.addArc(center: CGPoint(x: rect.minX + bl, y: rect.maxY - bl), radius: bl,
                    startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + tl))
        path.addArc(center: CGPoint(x: rect.minX + tl, y: rect.minY + tl), radius: tl,
                    startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        path.closeSubpath()
        return path
    }
}

/// Conteúdo da mensagem original exibida acima de uma resposta.
struct QuotedMessage: Equatable {
    /// `nil` quando não sabemos quem escreveu a original — ela pode não estar mais
    /// carregada em memória.
    var author: String?
    var text: String
}

/// Prévia da mensagem citada.
///
/// Um filete vertical e texto secundário, sem moldura nem fundo, para a citação ler como
/// parte da mensagem em vez de uma segunda bolha ou um botão. É o mesmo componente dentro
/// da bolha, acima de mídias e no composer, para a resposta ter sempre a mesma cara.
struct QuotedMessageView: View {

    /// `onAccent` = dentro da bolha azul; `onNeutral` = bolha recebida, mídia e composer.
    enum Tone {
        case onAccent
        case onNeutral
    }

    var quoted: QuotedMessage
    var tone: Tone
    var lineLimit: Int = 2

    var body: some View {
        HStack(spacing: 7) {
            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                .fill(barColor)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 1) {
                if let author = quoted.author {
                    Text(author)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(authorColor)
                }

                Text(quoted.text)
                    .font(.caption)
                    .foregroundStyle(textColor)
                    .lineLimit(lineLimit)
            }
            .multilineTextAlignment(.leading)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var barColor: Color {
        switch tone {
        case .onAccent: return .white.opacity(0.8)
        case .onNeutral: return .blue
        }
    }

    private var authorColor: Color {
        switch tone {
        case .onAccent: return .white.opacity(0.95)
        case .onNeutral: return .blue
        }
    }

    private var textColor: Color {
        switch tone {
        case .onAccent: return .white.opacity(0.75)
        case .onNeutral: return .secondary
        }
    }
}

struct BubbleView: View {

    var message: String
    var isCurrentUser: Bool
    /// Última mensagem do grupo: recebe a tail e o espaçamento maior.
    var isFirst: Bool
    /// Primeira mensagem do grupo. Usado só para arredondar os cantos.
    var isGroupStart: Bool = true
    /// Horário exibido dentro da bolha. `nil` esconde o horário.
    var time: String? = nil
    /// Mensagem citada, exibida no topo da bolha. `nil` quando não é uma resposta.
    var quoted: QuotedMessage? = nil
    var onQuotedTap: (() -> Void)? = nil

    @Environment(\.chatAvailableWidth) private var availableWidth

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            if let quoted {
                QuotedMessageView(quoted: quoted, tone: isCurrentUser ? .onAccent : .onNeutral)
                    .onTapGesture { onQuotedTap?() }
            }

            Content()
        }
        .padding(.horizontal, ChatBubbleLayout.horizontalPadding)
        .padding(.vertical, ChatBubbleLayout.verticalPadding)
        .background(
            isCurrentUser ? .blue : Color(uiColor: .secondarySystemBackground),
            in: bubbleShape
        )
        .background(alignment: isCurrentUser ? .bottomTrailing : .bottomLeading) {
            isFirst
            ?
            Image(isCurrentUser ? "outgoingTail" : "incomingTail")
                .renderingMode(.template)
                .foregroundStyle(isCurrentUser ? .blue : Color(uiColor: .secondarySystemBackground))
            :
            nil
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: isCurrentUser ? .trailing : .leading)
        .padding(isCurrentUser ? .leading : .trailing, ChatBubbleLayout.gutter(forAvailableWidth: availableWidth))
        .padding(.bottom, ChatBubbleLayout.bottomSpacing(isLastInGroup: isFirst))
    }

    //MARK: - Content

    /// O horário entra como um trecho invisível no fim do próprio texto e é desenhado por
    /// cima em `bottomTrailing`. Assim ele nunca cobre a mensagem: em textos curtos sobra
    /// espaço na mesma linha, e em textos longos o trecho reservado quebra junto com o
    /// texto, sem criar uma linha vazia grande.
    @ViewBuilder
    private func Content() -> some View {
        if let time {
            (
                Text(message)
                +
                Text(verbatim: "  \(time)")
                    .font(ChatBubbleLayout.timeFont)
                    .foregroundColor(.clear)
            )
            .foregroundStyle(isCurrentUser ? .white : .primary)
            .overlay(alignment: .bottomTrailing) {
                Text(time)
                    .font(ChatBubbleLayout.timeFont)
                    .foregroundStyle(isCurrentUser ? Color.white.opacity(0.7) : Color.secondary)
            }
        } else {
            Text(message)
                .foregroundStyle(isCurrentUser ? .white : .primary)
        }
    }

    //MARK: - Shape

    /// Os cantos do lado do remetente ficam menores no meio de um grupo, o que faz as
    /// mensagens consecutivas lerem como um bloco só.
    private var bubbleShape: BubbleShape {
        let full = ChatBubbleLayout.cornerRadius
        let senderTop = isGroupStart ? full : ChatBubbleLayout.groupedCornerRadius
        let senderBottom = isFirst ? full : ChatBubbleLayout.groupedCornerRadius

        return isCurrentUser
        ? BubbleShape(topLeading: full, topTrailing: senderTop, bottomLeading: full, bottomTrailing: senderBottom)
        : BubbleShape(topLeading: senderTop, topTrailing: full, bottomLeading: senderBottom, bottomTrailing: full)
    }
}

#Preview {
    VStack(spacing: 0) {
        BubbleView(message: "Ooi", isCurrentUser: false, isFirst: false, isGroupStart: true, time: "23:07")
        BubbleView(message: "Tudo bem por aí?", isCurrentUser: false, isFirst: true, isGroupStart: false, time: "23:07")
        BubbleView(message: "Já estou trabalhando na funcionalidade de mensagens, mano. Fique tranquilo 😉", isCurrentUser: true, isFirst: false, isGroupStart: true, time: "23:09")
        BubbleView(message: "👍", isCurrentUser: true, isFirst: true, isGroupStart: false, time: "23:09")
        BubbleView(
            message: "Boa! Já pode testar então.",
            isCurrentUser: false,
            isFirst: true,
            time: "23:11",
            quoted: QuotedMessage(author: "You", text: "Já estou trabalhando na funcionalidade de mensagens, mano. Fique tranquilo 😉")
        )
    }
    .padding(.horizontal, ChatBubbleLayout.screenMargin)
    .environment(\.chatAvailableWidth, 390 - ChatBubbleLayout.screenMargin * 2)
}
