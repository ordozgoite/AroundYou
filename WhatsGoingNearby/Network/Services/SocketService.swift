//
//  SocketService.swift
//  ChatApp
//
//  Created by Victor Ordozgoite on 19/01/23.
//

import Foundation
import SocketIO
import UIKit
import OSLog

enum SocketStatus: String {
    case connected
    case connecting
    case disconnected
}

// MARK: - Realtime Log

/// Log estruturado do fluxo de tempo real do chat.
///
/// Identificadores (uid, chatId, messageId) entram como `private`, então o sistema
/// os redige em produção e só os mostra durante depuração. Rótulos estáveis e
/// contadores entram como `public`. Token e conteúdo de mensagem nunca são registrados.
enum RealtimeLog {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "AroundYou",
        category: "ChatRealtime"
    )

    // Conexão

    static func connecting() {
        logger.info("socket: iniciando conexão")
    }

    static func connected() {
        logger.info("socket: conectado")
    }

    static func disconnected(reason: String) {
        logger.notice("socket: desconectado (\(reason, privacy: .public))")
    }

    static func reconnectAttempt() {
        logger.info("socket: tentando reconectar")
    }

    static func pingSucceeded() {
        logger.debug("socket: ping ok")
    }

    static func foregrounded() {
        logger.info("app: voltou ao primeiro plano, validando conexão")
    }

    static func zombieConnection() {
        logger.error("socket: conectado sem responder ao ping, forçando reconexão")
    }

    static func registered(userUid: String) {
        logger.info("socket: registrado para uid=\(userUid, privacy: .private(mask: .hash))")
    }

    static func authFailure(_ reason: String) {
        logger.error("socket: falha de autenticação (\(reason, privacy: .public))")
    }

    static func socketError(_ description: String) {
        logger.error("socket: erro (\(description, privacy: .public))")
    }

    // Assinaturas

    static func subscribed(event: String, owner: String) {
        logger.info("assinatura: \(event, privacy: .public) owner=\(owner, privacy: .private)")
    }

    static func unsubscribed(owner: String, count: Int) {
        logger.info("assinatura removida: \(count, privacy: .public) listener(s) owner=\(owner, privacy: .private)")
    }

    // Eventos

    static func eventReceived(_ event: String, chatId: String?) {
        logger.info("evento recebido: \(event, privacy: .public) chat=\(chatId ?? "-", privacy: .private(mask: .hash))")
    }

    static func eventIgnored(_ event: String, reason: String) {
        logger.info("evento ignorado: \(event, privacy: .public) motivo=\(reason, privacy: .public)")
    }

    static func parseFailure(event: String, error: Error) {
        logger.error("falha de parsing: \(event, privacy: .public) erro=\(String(describing: error), privacy: .public)")
    }

    // Mesclagem e sincronização

    static func merged(source: String, inserted: Int, updated: Int, reconciled: Int, duplicated: Int) {
        logger.info("merge (\(source, privacy: .public)): +\(inserted, privacy: .public) ~\(updated, privacy: .public) ↔\(reconciled, privacy: .public) =\(duplicated, privacy: .public)")
    }

    static func apiSync(source: String, pages: Int, fetched: Int) {
        logger.info("sync API (\(source, privacy: .public)): \(pages, privacy: .public) página(s), \(fetched, privacy: .public) mensagem(ns)")
    }

    static func apiSyncFailure(source: String) {
        logger.error("sync API falhou (\(source, privacy: .public))")
    }

    static func gapDetected(source: String) {
        logger.notice("lacuna detectada em \(source, privacy: .public), buscando páginas anteriores")
    }
}

@MainActor
final class SocketService: ObservableObject {
    static let shared = SocketService()

    let manager = SocketManager(
        socketURL: URL(string: Constants.API_URL)!,
        config: [
            .log(true),
            .compress,
            .reconnects(true),
            .reconnectAttempts(-1),
            .reconnectWait(5)
        ]
    )

    @Published var socket: SocketIOClient?
    @Published var status: SocketStatus = .disconnected

    /// Incrementado sempre que o app (re)estabelece ou revalida o canal de tempo real:
    /// conexão nova, novo `register` e retorno ao primeiro plano.
    ///
    /// As telas abertas observam este valor para reconciliar com a API. Usar um sinal
    /// próprio em vez de `status` evita recarregar a tela a cada piscada do indicador.
    @Published private(set) var resyncSignal: Int = 0

    /// uid efetivamente registrado no socket atual. `nil` significa "conexão ainda não registrada".
    private var registeredUserUid: String?

    private var listeners: [ListenerKey: UUID] = [:]

    private struct ListenerKey: Hashable {
        let owner: String
        let event: String
    }

    // In-app Notifications
    @Published var notificationQueue: [AppBannerNotification] = []
    @Published var currentNotification: AppBannerNotification? = nil
    @Published var pendingFullScreenRoute: AppRoute? = nil
    private var notificationTimer: Timer?
    private let notificationDuration = 5.0

    private var isValidatingConnection = false

    private init() {
        socket = manager.defaultSocket
        setupSocketEvents()
        startConnectionCheck()
        connectIfNeeded()
    }

    func connectIfNeeded() {
        guard let socket = socket else { return }

        switch socket.status {
        case .connected, .connecting:
            print("🔄 Já conectado ou conectando. Ignorando nova tentativa.")
        default:
            print("🛜 Iniciando conexão...")
            RealtimeLog.connecting()
            socket.connect()
        }
    }

    private func startConnectionCheck() {
        Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { _ in
            Task { @MainActor in
                await self.validateConnection()
            }
        }
    }

    /// Confirma, por ping, que o socket não está apenas "aparentemente" conectado.
    ///
    /// Quando o ping falha com o cliente ainda em `.connected`, `connect()` seria ignorado
    /// pelo próprio SocketIO e a conexão zumbi ficaria para sempre sem receber eventos —
    /// por isso derrubamos a conexão antes de tentar de novo.
    @discardableResult
    func validateConnection() async -> Bool {
        guard let socket = socket else { return false }
        // O ping tem timeout de 5s e o check periódico roda a cada 15s: sem esta guarda,
        // uma validação lenta e a do retorno ao foreground poderiam se sobrepor.
        guard !isValidatingConnection else { return status == .connected }

        isValidatingConnection = true
        defer { isValidatingConnection = false }

        let isConnected = await isSocketActuallyConnected()

        if isConnected {
            print("✅ Ping ok. Socket está realmente conectado.")
            RealtimeLog.pingSucceeded()
            self.status = .connected
            syncUserRegistration()
            return true
        }

        print("🔌 Ping falhou. Forçando reconexão.")
        // Uma reconexão em andamento continua sendo "conectando": marcar como desconectado
        // aqui só faria o indicador piscar em vermelho no meio da tentativa.
        if socket.status != .connecting {
            self.status = .disconnected
        }

        if socket.status == .connected {
            RealtimeLog.zombieConnection()
            registeredUserUid = nil
            socket.disconnect()
        }

        connectIfNeeded()
        return false
    }

    func isSocketActuallyConnected(timeout: TimeInterval = 5.0) async -> Bool {
        guard let socket = socket else { return false }
        if socket.status != .connected { return false }

        return await withCheckedContinuation { continuation in
            socket.emitWithAck("ping-check").timingOut(after: timeout) { data in
                if let response = data.first as? String, response == "pong" {
                    continuation.resume(returning: true)
                } else {
                    continuation.resume(returning: false)
                }
            }
        }
    }

    private func bumpResyncSignal() {
        resyncSignal &+= 1
    }
}

// MARK: - User Registration

extension SocketService {

    /// Garante que a conexão atual está registrada para o usuário logado.
    ///
    /// Antes, o `register` só acontecia dentro do evento de conexão. Como o socket conecta
    /// no lançamento do app — possivelmente antes de existir um uid —, quem logasse depois
    /// (primeiro login ou troca de conta) ficava sem receber nenhum evento até reiniciar o app.
    func syncUserRegistration(force: Bool = false) {
        guard let socket = socket, socket.status == .connected else { return }

        let userUid = LocalState.currentUserUid
        guard !userUid.isEmpty else {
            if registeredUserUid != nil {
                RealtimeLog.authFailure("registro ignorado: nenhum usuário autenticado")
            }
            return
        }

        guard force || registeredUserUid != userUid else { return }

        socket.emit("register", userUid)
        registeredUserUid = userUid
        RealtimeLog.registered(userUid: userUid)
        bumpResyncSignal()
    }

    /// Deve ser chamado quando a sessão do usuário muda: login, troca de conta ou logout.
    func handleUserSessionChanged() {
        let userUid = LocalState.currentUserUid

        guard !userUid.isEmpty else {
            registeredUserUid = nil
            socket?.disconnect()
            RealtimeLog.disconnected(reason: "logout")
            status = .disconnected
            return
        }

        let isNewUser = registeredUserUid != userUid
        connectIfNeeded()
        syncUserRegistration(force: isNewUser)
    }
}

// MARK: - Scoped Listeners

extension SocketService {

    /// Registra o listener de `event` pertencente a `owner`.
    ///
    /// Registrar o mesmo par (owner, event) de novo **substitui** o handler anterior em vez de
    /// empilhar outro, e `removeListeners(owner:)` remove apenas os listeners daquele dono.
    /// Isso evita os dois problemas do `socket.off(evento)` global: acumular handlers ao
    /// reentrar numa tela e derrubar o listener de outra tela que continua aberta.
    func addListener(for event: String, owner: String, handler: @escaping NormalCallback) {
        guard let socket = socket else { return }

        let key = ListenerKey(owner: owner, event: event)
        if let existingId = listeners[key] {
            socket.off(id: existingId)
        }

        listeners[key] = socket.on(event, callback: handler)
        RealtimeLog.subscribed(event: event, owner: owner)
    }

    func removeListeners(owner: String) {
        guard let socket = socket else { return }

        let keys = listeners.keys.filter { $0.owner == owner }
        guard !keys.isEmpty else { return }

        for key in keys {
            if let id = listeners.removeValue(forKey: key) {
                socket.off(id: id)
            }
        }
        RealtimeLog.unsubscribed(owner: owner, count: keys.count)
    }
}

// MARK: - Custom Events

extension SocketService {
    private func setupCustomEvents() {
        guard let socket = socket else { return }

        socket.on("message-notification") { data, ack in
            do {
                try self.attemptToDiplayChatMessageNotification(withData: data)
            } catch {
                print("Erro ao decodificar notificação de mensagem: \(error)")
                RealtimeLog.parseFailure(event: "message-notification", error: error)
            }
        }

        // ...
    }

    private func attemptToDiplayChatMessageNotification(withData data: [Any]) throws {
        let notificationData = try self.decodeChatMessageNotification(data)


        let notification = AppBannerNotification(
            title: notificationData.senderUsername,
            subtitle: notificationData.messageText,
            imageUrl: notificationData.senderProfilePicUrl,
            route: .messages(notificationData.chat)
        )

        self.enqueueNotification(notification)
    }


    private func decodeChatMessageNotification(_ message: [Any]) throws -> ChatMessageNotification {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: message[0], options: [])
            return try JSONDecoder().decode(ChatMessageNotification.self, from: jsonData)
        } catch {
            throw error
        }
    }
}

// MARK: - In-app Notifications

extension SocketService {
    func enqueueNotification(_ notification: AppBannerNotification) {
        notificationQueue.append(notification)
        showNextNotificationIfNeeded()
    }

    private func showNextNotificationIfNeeded() {
        guard currentNotification == nil, !notificationQueue.isEmpty else { return }

        let nextNotification = notificationQueue.removeFirst()
        currentNotification = nextNotification

        notificationTimer?.invalidate()
        notificationTimer = Timer.scheduledTimer(withTimeInterval: notificationDuration, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.dismissCurrentNotification()
            }
        }
    }

    func dismissCurrentNotification() {
        currentNotification = nil
        notificationTimer?.invalidate()
        notificationTimer = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.showNextNotificationIfNeeded()
        }
    }
}

// MARK: - Setup Events

extension SocketService {
    private func setupSocketEvents() {
        guard let socket = socket else { return }

        socket.removeAllHandlers()

        setupClientEvents()
        setupCustomEvents()
    }

    private func setupClientEvents() {
        guard let socket = socket else { return }

        socket.on(clientEvent: .connect) { [weak self] data, ack in
            guard let self = self else { return }
            print("✅ Socket conectado com userUid: \(LocalState.currentUserUid)")
            RealtimeLog.connected()
            self.status = .connected
            // Conexão nova: o registro anterior não vale mais, mesmo que o uid seja o mesmo.
            self.registeredUserUid = nil
            self.syncUserRegistration(force: true)
        }

        socket.on(clientEvent: .disconnect) { [weak self] data, _ in
            print("📡❌ Socket desconectado")
            RealtimeLog.disconnected(reason: (data.first as? String) ?? "desconhecido")
            self?.registeredUserUid = nil
            self?.status = .disconnected
        }

        socket.on(clientEvent: .reconnect) { [weak self] _, _ in
            // `.reconnect` marca o início da tentativa; o `register` acontece no `.connect`,
            // que o SocketIO reemite quando a reconexão conclui.
            print("🔁 Socket reconectando")
            RealtimeLog.reconnectAttempt()
            self?.registeredUserUid = nil
            self?.status = .connecting
        }

        socket.on(clientEvent: .reconnectAttempt) { [weak self] _, _ in
            print("🛜 Tentando reconectar...")
            RealtimeLog.reconnectAttempt()
            self?.status = .connecting
        }

        socket.on(clientEvent: .error) { _, data in
            print("❌ Erro no socket: \(data)")
            RealtimeLog.socketError(String(describing: data))
        }
    }
}

// MARK: - App Lifecycle

extension SocketService {
    /// Chamado pelo `scenePhase` do app quando a cena volta a ficar ativa.
    ///
    /// Voltar do background é o caso clássico do socket "conectado" que já não entrega nada:
    /// validamos por ping e, de todo modo, pedimos às telas abertas que reconciliem com a
    /// API — mensagens podem ter chegado enquanto o app dormia.
    ///
    /// O gatilho vem do `scenePhase` e não de `UIApplication.didBecomeActiveNotification`
    /// porque este é um app de ciclo de vida SwiftUI: o observador era registrado na criação
    /// do `@StateObject`, que o SwiftUI faz preguiçosamente no primeiro `body`, e podia
    /// perder a notificação inicial.
    func handleAppDidBecomeActive() {
        print("🔄 App voltou ao primeiro plano. Validando conexão.")
        RealtimeLog.foregrounded()
        Task { @MainActor in
            await self.validateConnection()
            self.bumpResyncSignal()
        }
    }
}
