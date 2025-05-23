//
//  MessageScreenWrapper.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 26/02/25.
//

import SwiftUI

struct MessageScreenWrapper: View {
    let chatId: String
    let username: String
    let otherUserUid: String
    let chatPic: String?
    let isLocked: Bool
    @ObservedObject var socket: SocketService
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            MessageScreen(
                chatId: chatId,
                username: username,
                otherUserUid: otherUserUid,
                chatPic: chatPic,
                isLocked: isLocked,
                socket: socket)
            .navigationBarItems(leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }, label: {
                Image(systemName: "xmark")
            }))
        }
    }
}
