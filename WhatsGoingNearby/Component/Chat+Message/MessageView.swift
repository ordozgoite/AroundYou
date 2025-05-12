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
    @State private var showingAlert = false
    let maxTranslation: CGFloat = 64
    var replyMessage: () -> ()
    var tappedRepliedMessage: () -> ()
    var resendMessage: () -> ()
    
    var body: some View {
        Time()
        
        Reply()
        
        HStack {
            if message.imageUrl != nil {
                ImageBubble(fromSource: .url)
            } else if message.image != nil {
                ImageBubble(fromSource: .uiImage)
            } else if let text = message.message {
                if text.isSingleEmoji {
                    Emoji(text)
                } else {
                    TextBubble(text)
                }
            }
            
            switch message.status {
            case .sent:
                EmptyView()
            case .sending:
                Sending()
            case .failed:
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
        if message.repliedMessageId != nil {
            HStack {
                if !message.isCurrentUser {
                    Image(systemName: "arrowshape.turn.up.right")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 20)
                        .foregroundStyle(.gray)
                }
                
                Text(message.repliedMessageText ?? "📷 Photo")
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
    
    //MARK: - Emoji
    
    @ViewBuilder
    private func Emoji(_ text: String) -> some View {
        if let emoji  = text.first {
            EmojiMessageView(emoji: emoji, isCurrentUser: message.isCurrentUser, isFirst: message.isFirst)
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
    
    //MARK: - Sending
    
    @ViewBuilder
    private func Sending() -> some View {
        ProgressView()
            .padding(.leading)
    }
    
    //MARK: - Failed
    
    @ViewBuilder
    private func Failed() -> some View {
        Image(systemName: "exclamationmark.circle")
            .foregroundStyle(.red)
            .onTapGesture {
                self.showingAlert = true
            }
            .confirmationDialog("This message was not sent", isPresented: $showingAlert, titleVisibility: .visible) {
                Button("Try again") {
                    resendMessage()
                }
            }
    }
}

#Preview {
    MessageView(
        message: FormattedMessage(
            id: "1",
            chatId: "1",
            message: "😉",
            imageUrl: nil,
//            imageUrl: "https://firebasestorage.googleapis.com:443/v0/b/aroundyou-b8364.appspot.com/o/post-image%2F8019D1A7-097F-45FA-B0FF-41959EC98789.jpg?alt=media&token=3c621a0c-46e2-405a-b5f5-3bff8f888e07",
            isCurrentUser: false,
            isFirst: true,
            repliedMessageText: "Tio, o que você está fazendo?",
            timeDivider: 1711774061000,
            status: .sent, 
            createdAt: 0
        ),
        replyMessage: {},
        tappedRepliedMessage: {},
        resendMessage: {}
    )
}
