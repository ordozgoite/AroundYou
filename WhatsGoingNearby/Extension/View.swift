//
//  View.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 15/02/24.
//

import Foundation
import SwiftUI
import Combine

/// Mesma vibração do helper de `View`, disponível fora de uma `View`
/// (view models e serviços, que também precisam avisar o usuário).
@MainActor
func triggerHapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
    let feedbackGenerator = UIImpactFeedbackGenerator(style: style)
    feedbackGenerator.prepare()
    feedbackGenerator.impactOccurred()
}

extension View {
    func hapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        triggerHapticFeedback(style: style)
    }
}

//MARK: - Swipe To Reply

/// Arrasto horizontal da mensagem para respondê-la, dirigido por um único
/// `UIPanGestureRecognizer` instalado no `UIScrollView` da conversa.
///
/// `DragGesture` não serve aqui. O SwiftUI concentra todos os gestos da tela num único
/// recognizer no hosting view raiz, e o delegate dele não concede simultaneidade ao
/// `UIScrollViewPanGestureRecognizer` — `.gesture` e `.simultaneousGesture` produzem
/// exatamente a mesma relação, porque é o mesmo objeto. Por isso qualquer `DragGesture`
/// dentro do ScrollView cancela a rolagem quando a lista está parada; com a lista já em
/// movimento o ScrollView agarra o toque antes de entregá-lo, o que explica a rolagem
/// funcionar só nesse caso.
///
/// Também não dá para conceder a simultaneidade pelo outro lado: trocar o delegate do pan
/// do `UIScrollView` faz o UIKit lançar exceção ("must have its scroll view as its
/// delegate").
///
/// Com recognizer próprio a arbitragem fica sob controle: ele só começa quando o movimento
/// é claramente horizontal para a direita, e declara simultaneidade com o pan da rolagem.
/// Num arrasto vertical ele nem entra em cena, então a rolagem segue nativa.
@MainActor
final class ChatSwipeDriver: NSObject, ObservableObject {

    /// Deslocamento máximo da bolha.
    static let maxOffset: CGFloat = 72
    /// A partir daqui, soltar confirma a resposta.
    static let replyThreshold: CGFloat = 56
    /// O quanto o horizontal precisa dominar o vertical para valer como swipe.
    private static let horizontalDominance: CGFloat = 1.2
    /// Faixa junto à borda esquerda reservada ao gesto de voltar da navegação.
    private static let navigationEdgeInset: CGFloat = 24

    struct Drag: Equatable {
        /// Em coordenadas globais: é por ele que cada linha descobre se o arrasto é dela.
        var start: CGPoint
        var offset: CGFloat
        var isFinished: Bool
    }

    @Published private(set) var drag: Drag?

    private var didReachThreshold = false
    private weak var installedOn: UIScrollView?
    private weak var popGesture: UIGestureRecognizer?

    /// Sobe a hierarquia a partir de uma view dentro da lista até achar o `UIScrollView`.
    /// Precisa ser um ancestral das bolhas — um recognizer por linha nunca chega a receber
    /// o toque, porque a view de um `.background` é irmã do conteúdo, não ancestral dele.
    func attach(startingFrom view: UIView) {
        var candidate: UIView? = view
        while let current = candidate, !(current is UIScrollView) {
            candidate = current.superview
        }
        guard let scrollView = installedOn ?? candidate as? UIScrollView else { return }

        if installedOn == nil {
            let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            pan.delegate = self
            // Não engole os toques do conteúdo: tap, long press e context menu seguem vivos.
            pan.cancelsTouchesInView = false
            scrollView.addGestureRecognizer(pan)
            installedOn = scrollView
        }

        // Pode ainda não haver navigation controller na primeira passada; `updateUIView`
        // chama de novo e a resolução acontece assim que a hierarquia estiver montada.
        if popGesture == nil {
            popGesture = scrollView.owningNavigationController?.interactivePopGestureRecognizer
        }
    }

    @objc private func handlePan(_ pan: UIPanGestureRecognizer) {
        guard let view = pan.view else { return }

        switch pan.state {
        case .began:
            drag = Drag(start: pan.location(in: nil), offset: 0, isFinished: false)

        case .changed:
            guard var current = drag else { return }
            current.offset = min(Self.maxOffset, max(0, pan.translation(in: view).x))
            drag = current

            if !didReachThreshold && current.offset >= Self.replyThreshold {
                didReachThreshold = true
                triggerHapticFeedback(style: .medium)
            }

        case .ended, .cancelled, .failed:
            guard var current = drag else { return }
            current.isFinished = true
            // Gesto interrompido não confirma resposta.
            if pan.state != .ended { current.offset = 0 }
            drag = current
            didReachThreshold = false

        default:
            break
        }
    }
}

extension ChatSwipeDriver: UIGestureRecognizerDelegate {

    /// Só para a direita, só quando o horizontal domina, e só longe da borda esquerda:
    /// lá o movimento pertence ao "voltar" da navegação, que é exatamente o mesmo gesto.
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return false }
        guard pan.location(in: nil).x > Self.navigationEdgeInset else { return false }

        let velocity = pan.velocity(in: pan.view)
        return velocity.x > 0 && abs(velocity.x) > abs(velocity.y) * Self.horizontalDominance
    }

    /// Para dois recognizers rodarem juntos basta um dos lados conceder. O `UIScrollView`
    /// não concede e não pode ser alterado, então a concessão sai daqui.
    ///
    /// A exceção é a navegação: conceder simultaneidade a ela fazia a tela inteira
    /// deslizar junto com a bolha, como se estivesse voltando.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        !isNavigationBack(other)
    }

    /// Enquanto o swipe da mensagem estiver em jogo, o "voltar" espera. Como só deixamos o
    /// nosso começar longe da borda, um gesto que nasce na borda faz o nosso falhar de
    /// imediato e a navegação segue normal.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldBeRequiredToFailBy other: UIGestureRecognizer) -> Bool {
        isNavigationBack(other)
    }

    private func isNavigationBack(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        gestureRecognizer === popGesture || gestureRecognizer is UIScreenEdgePanGestureRecognizer
    }
}

private extension UIResponder {
    /// Sobe a responder chain até o `UINavigationController` que hospeda a tela.
    var owningNavigationController: UINavigationController? {
        var responder: UIResponder? = self
        while let current = responder {
            if let navigationController = current as? UINavigationController {
                return navigationController
            }
            if let controller = current as? UIViewController, let navigationController = controller.navigationController {
                return navigationController
            }
            responder = current.next
        }
        return nil
    }
}

/// Ponte para instalar o recognizer. Precisa ficar dentro do `ScrollView` para que a
/// subida pela hierarquia encontre o `UIScrollView` da conversa.
struct ChatSwipeInstaller: UIViewRepresentable {

    let driver: ChatSwipeDriver

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        // A view serve só de âncora para achar o ScrollView; o recognizer vai para o
        // ScrollView, não para ela. Fora do hit test ela não intercepta toque nenhum.
        view.isUserInteractionEnabled = false
        // Na criação a view ainda não está na hierarquia; um ciclo depois já está.
        DispatchQueue.main.async { driver.attach(startingFrom: view) }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        driver.attach(startingFrom: uiView)
    }
}

private struct ChatSwipeDriverKey: EnvironmentKey {
    static let defaultValue: ChatSwipeDriver? = nil
}

extension EnvironmentValues {
    /// Guardado como valor de ambiente comum, e não como `EnvironmentObject`: assim as
    /// linhas não re-renderizam a cada quadro do arrasto — só a que está sendo arrastada
    /// mexe no próprio estado.
    var chatSwipeDriver: ChatSwipeDriver? {
        get { self[ChatSwipeDriverKey.self] }
        set { self[ChatSwipeDriverKey.self] = newValue }
    }
}

struct SwipeToReplyModifier: ViewModifier {

    let action: () -> Void

    @Environment(\.chatSwipeDriver) private var driver
    @State private var offset: CGFloat = 0
    @State private var isActive = false

    func body(content: Content) -> some View {
        content
            .offset(x: offset)
            .background(
                GeometryReader { geometry in
                    Color.clear.onReceive(dragPublisher) { drag in
                        handle(drag, rowFrame: geometry.frame(in: .global))
                    }
                }
            )
    }

    private var dragPublisher: AnyPublisher<ChatSwipeDriver.Drag, Never> {
        guard let driver else { return Empty().eraseToAnyPublisher() }
        return driver.$drag.compactMap { $0 }.eraseToAnyPublisher()
    }

    private func handle(_ drag: ChatSwipeDriver.Drag, rowFrame: CGRect) {
        if !isActive {
            // A linha entra no arrasto uma vez só, no começo, e pelo ponto de origem.
            guard !drag.isFinished, rowFrame.contains(drag.start) else { return }
            isActive = true
        }

        guard drag.isFinished else {
            offset = drag.offset
            return
        }

        if drag.offset >= ChatSwipeDriver.replyThreshold {
            action()
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            offset = 0
        }
        isActive = false
    }
}

extension View {
    /// Responder arrastando a mensagem para a direita, sem disputar o scroll vertical.
    /// Exige um `ChatSwipeDriver` no ambiente; sem ele o modificador fica inerte.
    func swipeToReply(perform action: @escaping () -> Void) -> some View {
        modifier(SwipeToReplyModifier(action: action))
    }
}

//MARK: - Text Input

@MainActor
private final class FirstResponderBox {
    static weak var responder: UIResponder?
}

extension UIResponder {
    /// Não existe API pública para obter o first responder. O caminho padrão é disparar
    /// uma ação sem alvo: o UIKit a entrega justamente a ele.
    static var currentFirstResponder: UIResponder? {
        FirstResponderBox.responder = nil
        UIApplication.shared.sendAction(#selector(UIResponder.ay_captureFirstResponder), to: nil, from: nil, for: nil)
        return FirstResponderBox.responder
    }

    @objc private func ay_captureFirstResponder() {
        FirstResponderBox.responder = self
    }
}

/// Encerra a composição de texto em andamento no campo focado e o esvazia de verdade.
///
/// O ditado do iOS — e teclados com IME — insere o que está sendo reconhecido como
/// *marked text*: um trecho provisório que vive no buffer do UIKit e só vira texto
/// definitivo quando a composição termina. Zerar apenas o `@Published` ligado ao campo não
/// toca nesse buffer, então, ao finalizar o ditado, o UIKit reaplicava o trecho e o texto
/// reaparecia no composer depois do envio.
///
/// `unmarkText()` confirma a composição; o `replace` apaga o conteúdo pelo caminho de
/// edição real do `UITextInput`, e não por trás dele; e as notificações ao `inputDelegate`
/// avisam o teclado de que o documento mudou fora dele — é isso que reinicia autocorreção,
/// texto preditivo e o buffer do ditado, sem precisar de delay nem de tirar o foco.
@MainActor
enum TextInputComposition {

    /// Confirma a composição em andamento e devolve o texto final do campo em foco.
    ///
    /// Chamado antes de ler a mensagem: é o que garante que o trecho ainda provisório do
    /// ditado entre no envio em vez de ficar para trás. Retorna `nil` quando não há campo
    /// de texto em foco — aí não existe composição para conciliar.
    static func finishComposition() -> String? {
        guard let input = UIResponder.currentFirstResponder as? UITextInput else { return nil }

        input.unmarkText()

        guard let fullRange = input.textRange(from: input.beginningOfDocument, to: input.endOfDocument) else { return nil }
        return input.text(in: fullRange)
    }

    /// Esvazia o conteúdo real do campo em foco, e não apenas o estado que o alimenta.
    static func clearActiveInput() {
        guard let input = UIResponder.currentFirstResponder as? UITextInput,
              let fullRange = input.textRange(from: input.beginningOfDocument, to: input.endOfDocument),
              input.offset(from: fullRange.start, to: fullRange.end) > 0
        else { return }

        input.unmarkText()
        input.inputDelegate?.textWillChange(input)
        input.replace(fullRange, withText: "")
        input.inputDelegate?.textDidChange(input)
    }
}
