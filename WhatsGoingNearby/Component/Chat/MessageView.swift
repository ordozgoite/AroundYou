//
//  MessageView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 29/03/24.
//

import SwiftUI

struct MessageView: View {
    
    var message: FormattedMessage
    
    var body: some View {
            Time()
            
            Reply()
            
            BubbleView(message: message.message, isCurrentUser: message.isCurrentUser, isFirst: message.isFirst)
    }
    
    //MARK: - Time
    
    @ViewBuilder
    private func Time() -> some View {
        if let timeDivider = message.timeDivider {
            Text(timeDivider.convertTimestampToDate().formatDatetoMessage())
                .foregroundStyle(.gray)
                .font(.caption)
                .padding(.vertical, 10)
        }
    }
    
    //MARK: - Reply
    
    @ViewBuilder
    private func Reply() -> some View {
        
        if let replyText = message.repliedMessageText {
            VStack(alignment: .leading, spacing: 0) {
                BubbleView(message: replyText, isCurrentUser: false, isFirst: false)
                    .opacity(0.5)
                
                Image(systemName: "point.topleft.down.curvedto.point.bottomright.up.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 20)
                    .foregroundStyle(.gray)
                    .padding(.leading, 32)
            }
            .scaleEffect(0.8)
        }
    }
}

#Preview {
    MessageView(message: FormattedMessage(id: "1", message: "Já estou trabalhando na funcionalidade de mensagens, mano. Fique tranquilo 😉", isCurrentUser: true, isFirst: true, repliedMessageText: "Tio, o que você está fazendo?", timeDivider: 1711774061000))
}
