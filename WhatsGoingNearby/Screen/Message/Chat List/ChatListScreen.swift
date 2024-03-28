//
//  ChatListScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 27/03/24.
//

import SwiftUI

struct ChatListScreen: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                NavigationLink(destination: MessageScreen()) {
                    ChatView(chatName: "vanylton", chatPic: "", lastMessageAt: .now, hasUnreadMessages: true, lastMessage: "Já terminou a tela de mensagens?", isMuted: true)
                }
                .buttonStyle(PlainButtonStyle())
                
                ChatView(chatName: "vanylton", chatPic: "", lastMessageAt: .now, hasUnreadMessages: true, lastMessage: "Já terminou a tela de mensagens?", isMuted: true)
                
                ChatView(chatName: "vanylton", chatPic: "", lastMessageAt: .now, hasUnreadMessages: true, lastMessage: "Já terminou a tela de mensagens?", isMuted: true)
                
                ChatView(chatName: "vanylton", chatPic: "", lastMessageAt: .now, hasUnreadMessages: true, lastMessage: "Já terminou a tela de mensagens?", isMuted: true)
                
                ChatView(chatName: "vanylton", chatPic: "", lastMessageAt: .now, hasUnreadMessages: true, lastMessage: "Já terminou a tela de mensagens?", isMuted: true)
                
                ChatView(chatName: "vanylton", chatPic: "", lastMessageAt: .now, hasUnreadMessages: true, lastMessage: "Já terminou a tela de mensagens?", isMuted: true)
                
                ChatView(chatName: "vanylton", chatPic: "", lastMessageAt: .now, hasUnreadMessages: true, lastMessage: "Já terminou a tela de mensagens?", isMuted: true)
                
                ChatView(chatName: "vanylton", chatPic: "", lastMessageAt: .now, hasUnreadMessages: true, lastMessage: "Já terminou a tela de mensagens?", isMuted: true)
                
                ChatView(chatName: "vanylton", chatPic: "", lastMessageAt: .now, hasUnreadMessages: true, lastMessage: "Já terminou a tela de mensagens?", isMuted: true)
                
                ChatView(chatName: "vanylton", chatPic: "", lastMessageAt: .now, hasUnreadMessages: true, lastMessage: "Já terminou a tela de mensagens?", isMuted: true)
                
                ChatView(chatName: "vanylton", chatPic: "", lastMessageAt: .now, hasUnreadMessages: true, lastMessage: "Já terminou a tela de mensagens?", isMuted: true)
            }
            
            .navigationTitle("Messages")
        }
    }
}

#Preview {
    ChatListScreen()
}
