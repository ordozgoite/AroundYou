//
//  MessageView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 29/03/24.
//

import SwiftUI

struct MessageView: View {
    
    var message: FormattedMessage
    /// Nome do outro participante, usado para identificar o autor da mensagem citada.
    var otherUsername: String
    /// Foto do outro participante, exibida ao lado do grupo de mensagens dele.
    var chatPic: String?

    @State private var showingAlert = false
    /// Retângulo da bolha desta mensagem, para o swipe-to-reply só pegar em cima dela.
    @State private var bubbleFrame = BubbleFrameBox()
    @Environment(\.chatAvailableWidth) private var availableWidth
    var replyMessage: () -> ()
    var tappedRepliedMessage: () -> ()
    var resendMessage: () -> ()

    var body: some View {
        Time()
        
        Reply()
        
        // Alinhado embaixo para a foto encostar na última bolha do grupo, como nos apps
        // nativos, em vez de flutuar no meio dele.
        HStack(alignment: .bottom) {
            SenderAvatar()

            // O preview local tem precedência: quando a mensagem enviada agora recebe a URL
            // do servidor, seguir mostrando a imagem que já está em memória evita a piscada
            // de recarregar a mesma imagem pela rede.
            if message.image != nil {
                ImageBubble(fromSource: .uiImage)
            } else if message.imageUrl != nil {
                ImageBubble(fromSource: .url)
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
        .swipeToReply(isCurrentUser: message.isCurrentUser, bubbleFrame: bubbleFrame) {
            replyMessage()
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
    
    //MARK: - Sender Avatar

    /// Foto do remetente, só na última mensagem do grupo. As anteriores reservam a coluna
    /// para os balões do grupo ficarem todos alinhados na mesma vertical.
    @ViewBuilder
    private func SenderAvatar() -> some View {
        if !message.isCurrentUser {
            Group {
                if message.isFirst {
                    ProfilePicView(profilePic: chatPic, size: ChatBubbleLayout.senderAvatarSize)
                } else {
                    Color.clear.frame(width: ChatBubbleLayout.senderAvatarSize, height: 1)
                }
            }
            // Acompanha o espaçamento que a bolha carrega embaixo, senão a foto desce junto
            // com ele e desalinha da base do balão.
            .padding(.bottom, ChatBubbleLayout.bottomSpacing(isLastInGroup: message.isFirst))
        }
    }

    //MARK: - Reply

    /// Mensagens de texto trazem a citação dentro da própria bolha. Aqui ficam só os casos
    /// em que não há bolha para acomodá-la: mídia e emoji avulso.
    @ViewBuilder
    private func Reply() -> some View {
        if let quoted, textBubbleContent == nil {
            QuotedMessageView(quoted: quoted, tone: .onNeutral)
                .frame(maxWidth: .infinity, alignment: message.isCurrentUser ? .trailing : .leading)
                .padding(message.isCurrentUser ? .leading : .trailing, ChatBubbleLayout.gutter(forAvailableWidth: availableWidth))
                .padding(.leading, message.isCurrentUser ? 0 : ChatBubbleLayout.incomingContentInset)
                .padding(.bottom, 4)
                .onTapGesture {
                    tappedRepliedMessage()
                }
        }
    }

    //MARK: - Quoted Message

    private var quoted: QuotedMessage? {
        guard message.repliedMessageId != nil else { return nil }
        return QuotedMessage(
            author: message.repliedMessageIsCurrentUser.map { $0 ? "You" : otherUsername },
            text: message.repliedMessageText ?? "📷 Photo"
        )
    }

    /// Texto que será renderizado como bolha — `nil` para mídia e emoji avulso.
    private var textBubbleContent: String? {
        guard message.image == nil, message.imageUrl == nil,
              let text = message.message, !text.isSingleEmoji
        else { return nil }
        return text
    }

    //MARK: - Text Bubble
    
    @ViewBuilder
    private func TextBubble(_ text: String) -> some View {
        BubbleView(
            message: text,
            isCurrentUser: message.isCurrentUser,
            isFirst: message.isFirst,
            isGroupStart: message.isGroupStart,
            time: message.createdAt.convertTimestampToDate().formatTimeToMessageBubble(),
            quoted: quoted,
            onQuotedTap: tappedRepliedMessage,
            bubbleFrame: bubbleFrame
        )
    }

    //MARK: - Emoji

    @ViewBuilder
    private func Emoji(_ text: String) -> some View {
        if let emoji = text.singleEmoji {
            EmojiMessageView(emoji: emoji, isCurrentUser: message.isCurrentUser, isFirst: message.isFirst, bubbleFrame: bubbleFrame)
        }
    }

    //MARK: - Image Bubble

    @ViewBuilder
    private func ImageBubble(fromSource imageSource: ImageSource) -> some View {
        ImageBubbleView(source: imageSource, imageUrl: message.imageUrl, uiImage: message.image, isCurrentUser: message.isCurrentUser, isFirst: message.isFirst, bubbleFrame: bubbleFrame)
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
            message: "Estou terminando o layout das mensagens 😉",
            imageUrl: nil,
//            imageUrl: "https://firebasestorage.googleapis.com:443/v0/b/aroundyou-b8364.appspot.com/o/post-image%2F8019D1A7-097F-45FA-B0FF-41959EC98789.jpg?alt=media&token=3c621a0c-46e2-405a-b5f5-3bff8f888e07",
            isCurrentUser: false,
            isFirst: true,
            isGroupStart: true,
            repliedMessageText: "Tio, o que você está fazendo?",
            repliedMessageId: "0",
            repliedMessageIsCurrentUser: true,
            timeDivider: 1711774061000,
            status: .sent,
            createdAt: 1711774061000
        ),
        otherUsername: "ordozgoite",
        chatPic: nil,
        replyMessage: {},
        tappedRepliedMessage: {},
        resendMessage: {}
    )
}
