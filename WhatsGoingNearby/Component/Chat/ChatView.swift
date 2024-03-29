//
//  ChatView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 27/03/24.
//

import SwiftUI

struct ChatView: View {
    
    let chat: FormattedChat
    
    var lastMessageStamp: String? {
        if let lastMessageAt = chat.lastMessageAt {
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            return formatter.string(from: lastMessageAt.convertTimestampToDate())
        } else {
            return nil
        }
    }
    
    var body: some View {
        HStack {
            ZStack {
                if chat.hasUnreadMessages {
                    Circle()
                        .foregroundStyle(.blue)
                }
            }
            .frame(width: 12)
            
            ProfilePicView(profilePic: chat.chatPic, size: 50)
            
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(chat.chatName)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    HStack(spacing: 10) {
                        Text(lastMessageStamp ?? "")
                            .foregroundStyle(.secondary)
                        
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                }
                
                HStack(alignment: .top, spacing: 4) {
                    Text(chat.lastMessage ?? "")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, minHeight: 40, alignment: .topLeading)
                    
                    if chat.isMuted {
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
    ChatView(chat: FormattedChat(id: UUID().uuidString, chatName: "vanylton", otherUserUid: "1", chatPic: "", lastMessageAt: 1711658090, hasUnreadMessages: true, lastMessage: "Já terminou a tela de mensagens?", isMuted: true))
}
