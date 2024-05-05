//
//  SocketService.swift
//  ChatApp
//
//  Created by Victor Ordozgoite on 19/01/23.
//

import Foundation
import SocketIO

//https://aroundyou-api-f3xzny4tlq-uw.a.run.app
//http://localhost:3000

class SocketService: ObservableObject {
    
    static let shared = SocketService()
    
    var socket: SocketIOClient!
    let manager = SocketManager(socketURL: URL(string: "http://localhost:3000")!, config: [.log(true), .compress])
    
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
