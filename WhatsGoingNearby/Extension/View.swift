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

//MARK: - Swipe To Go Back

/// Devolve o gesto nativo de voltar a uma tela que esconde o botão de voltar.
///
/// `navigationBarBackButtonHidden()` não desliga só o botão: o delegate que o SwiftUI instala
/// no `interactivePopGestureRecognizer` condiciona o gesto à existência dele, então a tela
/// fica sem swipe nenhum. Trocar esse delegate é o que reativa o gesto.
///
/// A troca preserva o gesto real da navegação — transição interativa, acompanhando o dedo,
/// com cancelamento e rubber band —, em vez de imitá-lo com um `DragGesture`. Quem desempilha
/// continua sendo o `UINavigationController`, e o `NavigationStack` atualiza o `path` a partir
/// disso, exatamente como já faz pelo botão de voltar padrão das demais telas.
///
/// O recognizer pertence ao `UINavigationController`, compartilhado por toda a pilha: por isso
/// o delegate original volta ao lugar assim que a tela sai.
private final class SwipeBackGestureController: NSObject, UIGestureRecognizerDelegate {

    private weak var navigationController: UINavigationController?
    private weak var replacedDelegate: UIGestureRecognizerDelegate?

    func enable(startingFrom view: UIView) {
        guard navigationController == nil,
              let controller = view.owningNavigationController,
              let gesture = controller.interactivePopGestureRecognizer
        else { return }

        navigationController = controller
        replacedDelegate = gesture.delegate
        gesture.delegate = self
    }

    func restore() {
        guard let gesture = navigationController?.interactivePopGestureRecognizer,
              gesture.delegate === self
        else { return }

        gesture.delegate = replacedDelegate
        navigationController = nil
    }

    /// Só há o que desempilhar acima da raiz. Sem essa guarda, um arrasto na primeira tela
    /// deixa a navegação travada.
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        (navigationController?.viewControllers.count ?? 0) > 1
    }

    /// Mesma exclusividade do gesto nativo: enquanto ele estiver em jogo, nenhum outro
    /// recognizer da tela entra junto no arrasto.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        false
    }
}

/// Ponte para alcançar o `UINavigationController` pela responder chain.
private struct SwipeBackGestureInstaller: UIViewRepresentable {

    func makeCoordinator() -> SwipeBackGestureController {
        SwipeBackGestureController()
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        // Na criação a view ainda não está na hierarquia; um ciclo depois já está.
        DispatchQueue.main.async { context.coordinator.enable(startingFrom: view) }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.enable(startingFrom: uiView)
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: SwipeBackGestureController) {
        coordinator.restore()
    }
}

extension View {
    /// Reativa o gesto nativo de voltar numa tela que usa `navigationBarBackButtonHidden()`.
    /// Sem esse modificador ela só sai pelo botão da toolbar.
    func swipeToGoBack() -> some View {
        background(SwipeBackGestureInstaller())
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

    enum Phase {
        case began
        case changed
        case finished
    }

    struct Drag: Equatable {
        /// Novo a cada gesto. É por ele que a linha sabe se já decidiu se o arrasto é dela.
        let id: UUID
        /// Em coordenadas globais: é por ele que cada linha descobre se o arrasto é dela.
        let start: CGPoint
        var offset: CGFloat
        var phase: Phase
    }

    @Published private(set) var drag: Drag?

    private weak var installedOn: UIScrollView?
    private weak var popGesture: UIGestureRecognizer?

    /// Áreas em que o arrasto tem dono, publicadas pelas próprias linhas.
    ///
    /// Sem isso o recognizer engatava em qualquer ponto da conversa e — por declarar
    /// precedência sobre o "voltar" — bloqueava a navegação em todo o espaço vazio, deixando
    /// só a faixa junto à borda funcionando.
    private var grabAreaSources: [ObjectIdentifier: BubbleFrameBox] = [:]

    func register(_ box: BubbleFrameBox) {
        grabAreaSources[ObjectIdentifier(box)] = box
    }

    func unregister(_ box: BubbleFrameBox) {
        grabAreaSources.removeValue(forKey: ObjectIdentifier(box))
    }

    private func hasMessage(at point: CGPoint) -> Bool {
        grabAreaSources.values.contains { $0.grabArea.contains(point) }
    }

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
            drag = Drag(id: UUID(), start: pan.location(in: nil), offset: 0, phase: .began)

        case .changed:
            guard var current = drag else { return }
            current.offset = min(Self.maxOffset, max(0, pan.translation(in: view).x))
            current.phase = .changed
            drag = current

        case .ended, .cancelled, .failed:
            guard var current = drag else { return }
            current.phase = .finished
            // Gesto interrompido não confirma resposta.
            if pan.state != .ended { current.offset = 0 }
            drag = current

        default:
            break
        }
    }
}

extension ChatSwipeDriver: UIGestureRecognizerDelegate {

    /// Só para a direita, só quando o horizontal domina, só longe da borda esquerda — lá o
    /// movimento pertence ao "voltar" da navegação, que é exatamente o mesmo gesto — e só
    /// quando o toque cai em cima de uma mensagem.
    ///
    /// A checagem da área é o que devolve o "voltar" em todo o espaço vazio da conversa: se
    /// o arrasto não tem dono, o recognizer nem entra em cena e a navegação recebe o gesto.
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return false }

        let location = pan.location(in: nil)
        guard location.x > Self.navigationEdgeInset else { return false }
        guard hasMessage(at: location) else { return false }

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

/// Retângulo desenhado da bolha e a área em que o arrasto conta como resposta a ela.
///
/// É uma classe de propósito: `frame` é reescrito a cada quadro de rolagem, e como estado
/// de View isso invalidaria a linha inteira sem parar.
final class BubbleFrameBox {

    /// Alvo mínimo confortável para começar o arrasto numa mensagem própria. Uma bolha
    /// curta é pequena demais para acertar, então a diferença vira folga à esquerda dela.
    private static let minimumGrabWidth: CGFloat = 160
    /// Teto dessa folga, para ela ficar logo à esquerda da bolha e não varrer a tela.
    private static let maximumGrabMargin: CGFloat = 96

    /// Define se há folga à esquerda da bolha.
    var isCurrentUser = false
    /// Retângulo desenhado da bolha, em coordenadas globais.
    var frame: CGRect = .zero

    /// Onde o dedo precisa começar para o arrasto ser desta mensagem.
    ///
    /// Recebida: só em cima da bolha. Passar o dedo ao lado dela não é responder ninguém.
    ///
    /// Própria: a bolha mais uma folga imediatamente à esquerda, proporcional ao quanto ela
    /// é estreita. Uma mensagem de poucas letras encosta na borda direita e vira um alvo
    /// pequeno demais; a folga dá onde pegar sem nunca chegar perto da borda esquerda.
    var grabArea: CGRect {
        guard frame != .zero else { return .zero }
        guard isCurrentUser else { return frame }

        let margin = min(Self.maximumGrabMargin, max(0, Self.minimumGrabWidth - frame.width))
        return CGRect(x: frame.minX - margin, y: frame.minY, width: frame.width + margin, height: frame.height)
    }
}

extension View {
    /// Mede a bolha onde ela ainda tem o próprio tamanho, antes de ser esticada para a
    /// largura toda pelo `frame(maxWidth: .infinity)` que a alinha na conversa.
    func reportsBubbleFrame(to box: BubbleFrameBox?) -> some View {
        background(
            GeometryReader { geometry in
                let _ = (box?.frame = geometry.frame(in: .global))
                Color.clear
            }
        )
    }
}

struct SwipeToReplyModifier: ViewModifier {

    let isCurrentUser: Bool
    let bubbleFrame: BubbleFrameBox?
    let action: () -> Void

    @Environment(\.chatSwipeDriver) private var driver
    @State private var offset: CGFloat = 0
    @State private var isActive = false
    @State private var decidedDragId: UUID?
    @State private var didReachThreshold = false

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
            .onAppear {
                // O driver precisa saber onde há mensagem para não engatar no vazio e
                // atropelar o gesto de voltar.
                bubbleFrame?.isCurrentUser = isCurrentUser
                if let bubbleFrame { driver?.register(bubbleFrame) }
            }
            .onDisappear {
                if let bubbleFrame { driver?.unregister(bubbleFrame) }
            }
    }

    private var dragPublisher: AnyPublisher<ChatSwipeDriver.Drag, Never> {
        guard let driver else { return Empty().eraseToAnyPublisher() }
        return driver.$drag.compactMap { $0 }.eraseToAnyPublisher()
    }

    /// Sem medição — telas que não reportam a bolha — vale a linha inteira, como antes.
    private func grabArea(fallingBackTo rowFrame: CGRect) -> CGRect {
        guard let area = bubbleFrame?.grabArea, area != .zero else { return rowFrame }
        return area
    }

    private func handle(_ drag: ChatSwipeDriver.Drag, rowFrame: CGRect) {
        // A dona do arrasto é decidida uma única vez, no primeiro evento dele. Reavaliar a
        // cada quadro deixava uma segunda mensagem entrar no gesto: o pan da rolagem roda
        // simultaneamente, então um swipe com qualquer componente vertical desliza a lista,
        // as linhas escorregam e o ponto de origem — que é fixo — acaba caindo dentro da
        // linha vizinha.
        //
        // Exigir a fase `.began` também mantém de fora quem só se inscreveu no meio do
        // gesto: `@Published` entrega o valor corrente a cada novo assinante, e a lista
        // reavalia corpo o tempo todo enquanto rola.
        if decidedDragId != drag.id {
            decidedDragId = drag.id
            isActive = drag.phase == .began && grabArea(fallingBackTo: rowFrame).contains(drag.start)
            didReachThreshold = false
        }

        guard isActive else { return }

        guard drag.phase == .finished else {
            offset = drag.offset
            // O aviso tátil é da linha, não do gesto. Ele morava no driver, que só olhava o
            // deslocamento: numa conversa curta o arrasto no vazio vibrava sem nenhuma
            // bolha ter se mexido.
            if !didReachThreshold && offset >= ChatSwipeDriver.replyThreshold {
                didReachThreshold = true
                triggerHapticFeedback(style: .medium)
            }
            return
        }

        if drag.offset >= ChatSwipeDriver.replyThreshold {
            action()
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            offset = 0
        }
        isActive = false
        didReachThreshold = false
    }
}

extension View {
    /// Responder arrastando a mensagem para a direita, sem disputar o scroll vertical.
    /// Exige um `ChatSwipeDriver` no ambiente; sem ele o modificador fica inerte.
    ///
    /// Passe `bubbleFrame` — alimentado por `reportsBubbleFrame(to:)` — para o arrasto valer
    /// só em cima da bolha. Sem ele, vale a linha inteira.
    func swipeToReply(
        isCurrentUser: Bool = false,
        bubbleFrame: BubbleFrameBox? = nil,
        perform action: @escaping () -> Void
    ) -> some View {
        modifier(SwipeToReplyModifier(isCurrentUser: isCurrentUser, bubbleFrame: bubbleFrame, action: action))
    }
}

//MARK: - Chat History Scroll Anchor

/// Mantém parado o que está na tela quando mensagens antigas entram acima.
///
/// Inserir conteúdo acima do visível não mexe no `contentOffset`, então tudo o que o
/// usuário está lendo desce de uma vez pela altura inserida. A correção é empurrar o offset
/// pela mesma altura.
///
/// O momento certo é quando o `contentSize` cresce — antes disso o layout ainda não
/// aconteceu e a altura nova não existe —, e é por isso que a observação é em KVO e não em
/// um `DispatchQueue.main.async` depois da inserção.
final class ChatHistoryScrollAnchor: NSObject, ObservableObject {

    /// Distância do topo a partir da qual a página anterior já é buscada — aproximadamente
    /// meia dúzia de mensagens, para o histórico chegar antes do usuário.
    private static let prefetchDistance: CGFloat = 400

    /// Folga dentro da qual a conversa ainda conta como "no fim": quem parou a poucos pontos
    /// da última mensagem continua acompanhando a conversa, não lendo o histórico.
    private static let bottomProximity: CGFloat = 120

    /// Verdadeiro enquanto a rolagem estiver perto do começo do que já está carregado.
    /// Publica só na virada, não a cada quadro.
    @Published private(set) var isApproachingTop = false

    /// Verdadeiro quando a conversa está no fim, ou bem perto dele.
    ///
    /// É uma pergunta pontual — feita no instante em que uma mensagem chega — e por isso não
    /// é `@Published`: publicá-la reavaliaria a conversa inteira a cada quadro de rolagem.
    ///
    /// Sem `UIScrollView` ainda encontrado, responde que sim: é o estado da conversa recém
    /// aberta, e é também o comportamento que existia antes desta distinção.
    var isAtBottom: Bool {
        guard let scrollView else { return true }

        let insets = scrollView.adjustedContentInset
        // Conteúdo que cabe na tela não rolou: está tudo visível, o fim inclusive.
        guard scrollView.contentSize.height + insets.top + insets.bottom > scrollView.bounds.height else { return true }

        let offsetAtBottom = scrollView.contentSize.height + insets.bottom - scrollView.bounds.height
        return offsetAtBottom - scrollView.contentOffset.y <= Self.bottomProximity
    }

    /// Só passa a valer depois de posicionar a conversa no fim. Até lá o `contentOffset`
    /// é zero e pediria histórico sem o usuário ter rolado nada.
    var isPrefetchEnabled = false

    private weak var scrollView: UIScrollView?
    private var contentSizeObservation: NSKeyValueObservation?
    private var contentOffsetObservation: NSKeyValueObservation?
    private var heightBeforePrepend: CGFloat?

    /// Sobe a hierarquia a partir de uma view dentro da lista até achar o `UIScrollView`.
    func attach(startingFrom view: UIView) {
        guard scrollView == nil else { return }

        var candidate: UIView? = view
        while let current = candidate, !(current is UIScrollView) {
            candidate = current.superview
        }
        guard let scroll = candidate as? UIScrollView else { return }

        scrollView = scroll
        contentSizeObservation = scroll.observe(\.contentSize) { [weak self] scroll, _ in
            self?.compensateForPrependedContent(in: scroll)
        }
        contentOffsetObservation = scroll.observe(\.contentOffset) { [weak self] scroll, _ in
            self?.updateProximityToTop(in: scroll)
        }
    }

    /// A posição da rolagem é lida direto do `UIScrollView`, e não por `PreferenceKey` com
    /// `GeometryReader`: nesta hierarquia — `ScrollView` > `ScrollViewReader` > `ZStack` —
    /// o `GeometryReader` até é reavaliado, mas a preferência não chega ao
    /// `onPreferenceChange`, que só recebe o valor padrão uma única vez.
    private func updateProximityToTop(in scrollView: UIScrollView) {
        guard isPrefetchEnabled else { return }
        // Conteúdo que cabe na tela ainda não rolou: buscar aqui seria buscar na abertura.
        guard scrollView.contentSize.height > scrollView.bounds.height else { return }

        let isNearTop = scrollView.contentOffset.y < Self.prefetchDistance
        guard isNearTop != isApproachingTop else { return }
        isApproachingTop = isNearTop
    }

    /// Fotografa a altura atual, imediatamente antes da inserção e no mesmo ciclo dela.
    func captureBeforePrepend() {
        heightBeforePrepend = scrollView?.contentSize.height
    }

    private func compensateForPrependedContent(in scrollView: UIScrollView) {
        // Sem foto pendente, este crescimento é de outra coisa — mensagem nova, teclado —
        // e não deve mexer na posição.
        guard let previousHeight = heightBeforePrepend else { return }
        heightBeforePrepend = nil

        let insertedHeight = scrollView.contentSize.height - previousHeight
        guard insertedHeight > 0 else { return }
        scrollView.contentOffset.y += insertedHeight
    }
}

/// Ponte para achar o `UIScrollView`. Precisa ficar dentro dele.
struct ChatHistoryAnchorInstaller: UIViewRepresentable {

    let anchor: ChatHistoryScrollAnchor

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        DispatchQueue.main.async { anchor.attach(startingFrom: view) }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        anchor.attach(startingFrom: uiView)
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
