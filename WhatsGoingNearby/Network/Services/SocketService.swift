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
    let manager = SocketManager(socketURL: URL(string: Constants.API_URL)!, config: [.log(true), .compress, .reconnects(true), .reconnectAttempts(-1), .reconnectWait(5)])
    
    @Published var socket: SocketIOClient?
    @Published var status: SocketStatus = .disconnected
    
    init() {
        socket = manager.defaultSocket
        connect()
        observeAppLifecycle()
        startConnectionCheck()
    }
    
    private func connect() {
        print("🛜 Trying to connect...")

        socket?.removeAllHandlers()

        socket?.on(clientEvent: .connect) { data, ack in
            print("✅ Socket connected with userUid: \(LocalState.currentUserUid)")
            self.socket?.emit("register", LocalState.currentUserUid)
            self.status = .connected
        }

        socket?.on(clientEvent: .disconnect) { data, ack in
            print("📡❌ Socket disconnected")
            self.status = .disconnected
        }

        socket?.on(clientEvent: .reconnect) { data, ack in
            print("✅ Socket reconnected")
            self.status = .connected
        }

        socket?.on(clientEvent: .reconnectAttempt) { data, ack in
            print("🛜 Attempting to reconnect...")
            self.status = .connecting
        }

        socket?.on(clientEvent: .error) { data, ack in
            print("❌ Socket error: \(data)")
        }

        if socket?.status != .connected && socket?.status != .connecting {
            socket?.connect()
        }
    }

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
            socket?.connect()
        }
    }

    private func startConnectionCheck() {
        Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { _ in
            Task { @MainActor in
                if self.status == .disconnected || self.socket?.status != .connected {
                    print("🔁 Forçando reconexão por segurança.")
                    self.socket?.connect()
                }
            }
        }
    }

}

