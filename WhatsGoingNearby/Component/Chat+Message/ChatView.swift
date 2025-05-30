//
//  ChatView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 27/03/24.
//

import SwiftUI

struct ChatView: View {
    
    let chat: FormattedChat
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    
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
        HStack(alignment: .top) {
            HStack(spacing: 4) {
                HStack(alignment: .center) {
                    UnreadMarker()
                    
                    ProfilePicView(profilePic: chat.chatPic, size: 64)
                        .padding(.trailing, 8)
                }
                
                VStack(alignment: .leading, spacing: 0) {
                    Username()
                    
                    LastMessage()
                }
            }
            
            Spacer()
            
            HStack(alignment: .top) {
                LastMessageTime()
                
                VStack {
                    Chevron()
                    
                    MuteMarker()
                }
            }
        }
//        .frame(alignment: .center)
//        .padding(.vertical, 8)
    }
    
    // MARK: - Unread
    
    @ViewBuilder
    private func UnreadMarker() -> some View {
        ZStack {
            if chat.hasUnreadMessages {
                Circle()
                    .foregroundStyle(.blue)
            }
        }
        .frame(width: 8, alignment: .center)
    }
    
    // MARK: - Username
    
    @ViewBuilder
    private func Username() -> some View {
        Text(chat.chatName)
            .font(.headline)
            .lineLimit(1)
    }
    
    // MARK: - Last Message
    
    @ViewBuilder
    private func LastMessage() -> some View {
        Text(chat.lastMessage ?? "📷 Photo")
            .foregroundStyle(.secondary)
            .font(.subheadline)
            .fixedSize(horizontal: false, vertical: true)
            .lineLimit(2)
            .frame(maxWidth: .infinity, minHeight: 40, alignment: .topLeading)
    }
    
    // MARK: - Last Message Time
    
    @ViewBuilder
    private func LastMessageTime() -> some View {
        Text(lastMessageStamp ?? "")
            .foregroundStyle(.secondary)
            .font(.subheadline)
    }
    
    // MARK: - Chevron
    
    @ViewBuilder
    private func Chevron() -> some View {
        Image(systemName: "chevron.right")
            .foregroundColor(.gray)
            .imageScale(.small)
    }
    
    // MARK: - Mute Marker
    
    @ViewBuilder
    private func MuteMarker() -> some View {
        if chat.isMuted {
            Image(systemName: "bell.slash.fill")
                .foregroundColor(.gray)
                .imageScale(.small)
        }
    }
}

#Preview {
    ChatView(chat: FormattedChat(
        id: UUID().uuidString,
        chatName: "vanylton.bezerra.gmeam",
        otherUserUid: "1",
        chatPic: "",
        lastMessageAt: 1711658090,
        hasUnreadMessages: true,
        lastMessage: "Já terminou a tela de mensagens? Posso começar a divulgar?",
        isMuted: true,
        isLocked: true
    ))
}
