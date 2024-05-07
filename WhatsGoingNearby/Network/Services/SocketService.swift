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
//    private var connectedChatIds: [String] = []
    
    init() {
        socket = manager.defaultSocket
        socket.connect()
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
//        if !connectedChatIds.contains(chatId) {
            socket.emit("join-room", chatId)
//            connectedChatIds.append(chatId)
//        }
    }

//    func emit(_ event: String, _ data: [String: Any]) {
//        socket.emit(event, data)
//    }
}
