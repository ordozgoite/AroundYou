//
//  SocketService.swift
//  ChatApp
//
//  Created by Victor Ordozgoite on 19/01/23.
//

import Foundation
import SocketIO

class SocketService: ObservableObject {
    
    static let shared = SocketService()
    
    var socket: SocketIOClient!
    let manager = SocketManager(socketURL: URL(string: "https://odd-rose-moose-sock.cyclic.app")!, config: [.log(true), .compress])
    
    init() {
        socket = manager.defaultSocket
    }
    
    func connect() {
        socket.connect()
    }

    func disconnect() {
        socket.disconnect()
    }
    
    func getSocket() -> SocketIOClient {
        return socket
    }

    func on(_ event: String, callback: @escaping (Any?) -> ()) {
        socket.on(event) { data, ack in
            callback(data)
        }
    }

//    func emit(_ event: String, _ data: [String: Any]) {
//        socket.emit(event, data)
//    }
}
