//
//  SocketService.swift
//  ChatApp
//
//  Created by Victor Ordozgoite on 19/01/23.
//

import Foundation
import SocketIO

@MainActor
final class SocketService: ObservableObject {
    
    var socket: SocketIOClient!
    let manager = SocketManager(socketURL: URL(string: Constants.serverUrl)!, config: [.log(true), .compress])
    
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    
    init() {
        socket = manager.defaultSocket
        setupSocket()
    }
    
    private func setupSocket() {
        socket.on(clientEvent: .connect) { _, _ in
            print("Socket connected")
            self.reconnectAttempts = 0
        }
        
        socket.on(clientEvent: .disconnect) { _, _ in
            print("Socket disconnected")
            self.reconnectIfNeeded()
        }
        
        socket.connect()
    }
    
    private func reconnectIfNeeded() {
        if reconnectAttempts < maxReconnectAttempts {
            print("Attempting to reconnect...")
            socket.connect()
            reconnectAttempts += 1
        } else {
            print("Max reconnect attempts reached.")
            // You may want to handle this case, e.g., inform the user or take appropriate action
        }
    }
    
    //    func connect() {
    //        socket.connect()
    //    }
    
    func disconnect() {
        socket.disconnect()
    }
    
    //    func getSocket() -> SocketIOClient {
    //        return socket
    //    }
    
    func on(_ event: String, callback: @escaping (Any?) -> ()) {
        socket.on(event) { data, ack in
            callback(data)
        }
    }
    
    func joinChat(_ chatId: String) {
        socket.emit("join-room", chatId)
    }
    
    //    func emit(_ event: String, _ data: [String: Any]) {
    //        socket.emit(event, data)
    //    }
}
