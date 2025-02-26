//
//  CommunityMessageView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 24/02/25.
//

import SwiftUI

struct CommunityMessageView: View {
    
    var message: FormattedCommunityMessage
    
    @State private var translation: CGSize = .zero
    @State private var showingAlert = false
    let maxTranslation: CGFloat = 64
    var replyMessage: () -> ()
    var tappedRepliedMessage: () -> ()
    var resendMessage: () -> ()
    
    var body: some View {
        Time()
        
        Username()
        
        Reply()
        
        HStack {
            HStack {
                if message.text.isSingleEmoji {
                    Emoji(message.text)
                } else {
                    if message.shouldDisplaySenderProfilePic {
                        ProfilePicView(profilePic: message.senderProfilePic, size: 32)
                    } else {
                        // Gambiarra para que as mensagens fiquem todas alinhadas
                        // Sem isso, a mensagem que acompanha a imagem de perfil ficaria desalinhada com as demais
                        // Pra resolver isso, eu criei esse espaçamento para as mansagens que não acompanham a imagem
                        Spacer().frame(width: 40)
                    }
                    
                    TextBubble()
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
    
    // MARK: - Username
    @ViewBuilder
    private func Username() -> some View {
        if message.shouldDispaySenderUsername {
            HStack {
                Spacer().frame(width: 40)
                Text(message.senderUsername)
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
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
                
                Text(message.repliedMessageText ?? "")
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
    private func TextBubble() -> some View {
        BubbleView(message: message.text, isCurrentUser: message.isCurrentUser, isFirst: message.isFirst)
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
    CommunityMessageView(
        message: FormattedCommunityMessage(
            id: UUID().uuidString,
            communityId: UUID().uuidString,
            text: "Olá, pessoal!",
            isCurrentUser: false,
            isFirst: true,
            repliedMessageText: nil,
            repliedMessageId: nil,
            timeDivider: nil,
            status: .sent,
            createdAt: 1609459200,
            senderUsername: "amanda",
            senderProfilePic: nil,
            shouldDispaySenderUsername: true,
            shouldDisplaySenderProfilePic: true
        ),
        replyMessage: {},
        tappedRepliedMessage: {},
        resendMessage: {}
    )
}
