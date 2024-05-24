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

@MainActor
final class SocketService: ObservableObject {
    
    @Published var socket: SocketIOClient?
    let manager = SocketManager(socketURL: URL(string: Constants.serverUrl)!, config: [.log(true), .compress])
    @Published var status: SocketStatus = .disconnected
    
    private var timer: Timer?
    
    init() {
        socket = manager.defaultSocket
        setupSocket()
    }
    
    private func setupSocket() {
        print("🛜 setupSocket")
        connect()
        updateConnectionStatus()
    }
    
    private func connect() {
        print("🛜 Trying to connect...")
        socket?.connect()
    }
    
    private func updateConnectionStatus() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.checkConnection()
        }
        timer?.fire()
    }
    
    private func checkConnection() {
        print("🛜 checkConnection")
        if socket?.status != .connected {
            print("😞 Disconnected")
            if socket?.status != .connecting {
                connect()
            }
        } else {
            print("✅ Connected")
        }
        self.status = getSocketStatus()
    }
    
    func disconnect() {
        print("❌ disconnect")
        socket?.disconnect()
    }
    
    func on(_ event: String, callback: @escaping (Any?) -> ()) {
        socket?.on(event) { data, ack in
            callback(data)
        }
    }
    
    func joinChat(_ chatId: String) {
        print("🛜 joinChat")
        socket?.emit("join-room", chatId)
    }
    
    private func getSocketStatus() -> SocketStatus {
        switch socket?.status {
        case .notConnected:
            return .disconnected
        case .disconnected:
            return .disconnected
        case .connecting:
            return .connecting
        case .connected:
            return .connected
        case nil:
            return .disconnected
        }
    }
    
//    private func getStatus() -> String {
//        switch socket?.status {
//        case .notConnected:
//            return "notConnected"
//        case .disconnected:
//            return "disconnected"
//        case .connecting:
//            return "connecting"
//        case .connected:
//            return "connected"
//        case .none:
//            return "nil"
//        }
//    }
}
