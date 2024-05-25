//
//  SocketService.swift
//  ChatApp
//
//  Created by Victor Ordozgoite on 19/01/23.
//

import Foundation
import SocketIO

enum SocketStatus: String {
    case connected
    case connecting
    case disconnected
}

//"http://localhost:3000"

@MainActor
final class SocketService: ObservableObject {
    
    @Published var socket: SocketIOClient?
    let manager = SocketManager(socketURL: URL(string: Constants.serverUrl)!, config: [.log(true), .compress, .reconnects(true), .reconnectAttempts(-1), .reconnectWait(5)])
    @Published var status: SocketStatus = .disconnected
    
    init() {
        socket = manager.defaultSocket
        connect()
    }
    
    private func connect() {
        print("🛜 Trying to connect...")

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

        socket?.connect()

        socket?.on("message") { data, ack in
            if let message = data[0] as? String {
                print("✉️ Received message: \(message)")
            }
        }
    }
}
