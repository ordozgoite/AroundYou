//
//  SocketService.swift
//  ChatApp
//
//  Created by Victor Ordozgoite on 19/01/23.
//

import Foundation
import SocketIO
import UIKit

enum SocketStatus: String {
    case connected
    case connecting
    case disconnected
}

@MainActor
final class SocketService: ObservableObject {
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
    
    // In-app Notifications
    @Published var notificationQueue: [AppBannerNotification] = []
    @Published var currentNotification: AppBannerNotification? = nil
    @Published var pendingFullScreenRoute: AppRoute? = nil
    private var notificationTimer: Timer?
    private let notificationDuration = 5.0
    
    init() {
        socket = manager.defaultSocket
        setupSocketEvents()
        observeAppLifecycle()
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
            socket.connect()
        }
    }
    
    private func startConnectionCheck() {
        Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { _ in
            Task { @MainActor in
                if self.status == .disconnected || self.socket?.status != .connected {
                    print("🛠 Reconexão forçada por segurança")
                    self.connectIfNeeded()
                }
            }
        }
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
            socket.emit("register", LocalState.currentUserUid)
            self.status = .connected
        }
        
        socket.on(clientEvent: .disconnect) { [weak self] _, _ in
            print("📡❌ Socket desconectado")
            self?.status = .disconnected
        }
        
        socket.on(clientEvent: .reconnect) { [weak self] _, _ in
            print("🔁 Socket reconectado")
            self?.status = .connected
        }
        
        socket.on(clientEvent: .reconnectAttempt) { [weak self] _, _ in
            print("🛜 Tentando reconectar...")
            self?.status = .connecting
        }
        
        socket.on(clientEvent: .error) { _, data in
            print("❌ Erro no socket: \(data)")
        }
    }
}

// MARK: - App Lifecycle

extension SocketService {
    private func observeAppLifecycle() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func appDidBecomeActive() {
        if status != .connected {
            print("🔄 App voltou ao primeiro plano. Tentando reconectar.")
            connectIfNeeded()
        }
    }
}


