//
//  MessageView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 29/03/24.
//

import SwiftUI

struct MessageView: View {
    
    var message: FormattedMessage
    
    @State private var translation: CGSize = .zero
    let maxTranslation: CGFloat = 64
    var replyMessage: () -> ()
    
    var body: some View {
        Time()
        
        Reply()
        
        BubbleView(message: message.message, isCurrentUser: message.isCurrentUser, isFirst: message.isFirst)
            .offset(x: translation.width, y: 0)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        if gesture.translation.width > 0 {
                            translation.width = min(maxTranslation, gesture.translation.width)
                        }
                    }
                    .onEnded { gesture in
                        if gesture.translation.width > maxTranslation {
                            hapticFeedback(style: .heavy)
                            replyMessage()
                        }
                        withAnimation {
                            translation = .zero
                        }
                    }
            )
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
            HStack {
                if !message.isCurrentUser {
                    Image(systemName: "arrowshape.turn.up.right")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 20)
                        .foregroundStyle(.gray)
                }
                
                Text(replyText)
                    .foregroundStyle(.gray)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray, lineWidth: 2)
                    )
                
                if message.isCurrentUser {
                    Image(systemName: "arrowshape.turn.up.left")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 20)
                        .foregroundStyle(.gray)
                }
            }
            .scaleEffect(0.8)
            .frame(maxWidth: .infinity, alignment: message.isCurrentUser ? .trailing : .leading)
        }
    }
}

#Preview {
    MessageView(message: FormattedMessage(id: "1", message: "Já estou trabalhando na funcionalidade de mensagens, mano. Fique tranquilo 😉", isCurrentUser: false, isFirst: true, repliedMessageText: "Tio, o que você está fazendo?", timeDivider: 1711774061000), replyMessage: {})
}
