//
//  ChatView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 27/03/24.
//

import SwiftUI

struct ChatView: View {
    
    let chatName: String
    let chatPic: String
    let lastMessageAt: Date
    let hasUnreadMessages: Bool
    let lastMessage: String
    let isMuted: Bool // take off?
    
    var lastMessageStamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: lastMessageAt)
    }
    
    var body: some View {
        HStack {
            ZStack {
                if hasUnreadMessages {
                    Circle()
                        .foregroundStyle(.blue)
                }
            }
            .frame(width: 12)
            
            Image(systemName: "person.circle.fill")
                .resizable()
                .foregroundStyle(.gray)
                .frame(width: 50, height: 50, alignment: .center)
            
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(chatName)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    HStack(spacing: 10) {
                        Text(lastMessageStamp)
                            .foregroundStyle(.secondary)
                        
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                }
                
                HStack(alignment: .top, spacing: 4) {
                    Text(lastMessage)
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, minHeight: 40, alignment: .topLeading)
                    
                    if isMuted {
                        Image(systemName: "bell.slash.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.secondary)
                            .frame(width: 12)
                            .padding(.top, 4)
                    }
                }
                
                Divider()
            }
        }
        .padding(.vertical, 4)
        .padding([.leading,.trailing], 10)
        .background(Color(uiColor: .systemBackground))
    }
}

#Preview {
    ChatView(chatName: "vanylton", chatPic: "", lastMessageAt: .now, hasUnreadMessages: true, lastMessage: "Já terminou a tela de mensagens?", isMuted: true)
}
