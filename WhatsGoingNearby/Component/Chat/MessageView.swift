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
    var tappedRepliedMessage: () -> ()
    
    var body: some View {
        Time()
        
        Reply()
        
        HStack {
            if message.imageUrl != nil {
                ImageBubble(fromSource: .url)
            } else if message.image != nil {
                ImageBubble(fromSource: .uiImage)
            }
            
            if let text = message.message {
                TextBubble(text)
            }
            
            if message.status == .failed {
                Failed()
            }
        }
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
            .onTapGesture {
                tappedRepliedMessage()
            }
        }
    }
    
    //MARK: - Text Bubble
    
    @ViewBuilder
    private func TextBubble(_ text: String) -> some View {
        BubbleView(message: text, isCurrentUser: message.isCurrentUser, isFirst: message.isFirst)
            .opacity(message.status == .sent ? 1 : 0.5) // ?
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
    
    //MARK: - Image Bubble
    
    @ViewBuilder
    private func ImageBubble(fromSource imageSource: ImageSource) -> some View {
        ImageBubbleView(source: imageSource, imageUrl: message.imageUrl, uiImage: message.image, isCurrentUser: message.isCurrentUser)
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
    
    //MARK: - Failed
    
    @ViewBuilder
    private func Failed() -> some View {
        Image(systemName: "exclamationmark.circle")
            .foregroundStyle(.red)
    }
}

#Preview {
    MessageView(
        message: FormattedMessage(
            id: "1",
            message: "Já estou trabalhando na funcionalidade de mensagens, mano. Fique tranquilo 😉",
            imageUrl: "https://firebasestorage.googleapis.com:443/v0/b/aroundyou-b8364.appspot.com/o/post-image%2F8019D1A7-097F-45FA-B0FF-41959EC98789.jpg?alt=media&token=3c621a0c-46e2-405a-b5f5-3bff8f888e07",
            isCurrentUser: false,
            isFirst: true,
            repliedMessageText: "Tio, o que você está fazendo?",
            timeDivider: 1711774061000,
            status: .sent
        ),
        replyMessage: {},
        tappedRepliedMessage: {}
    )
}
