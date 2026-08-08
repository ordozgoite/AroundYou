//
//  MessageScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 27/03/24.
//

import SwiftUI
import PhotosUI
import CoreData
import SocketIO

struct MessageScreen: View {
    
    let chatId: String
    let username: String
    let otherUserUid: String
    let chatPic: String?
    @State var isLocked: Bool
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @EnvironmentObject var socket: SocketService
    @EnvironmentObject var navCoordinator: NavigationCoordinator
    @StateObject private var messageVM = MessageViewModel()
    @FocusState private var isFocused: Bool
    
    var body: some View {
        // A largura máxima das bolhas é derivada da largura real do container, e não de
        // um valor fixo, para acompanhar os diferentes tamanhos de iPhone.
        GeometryReader { geometry in
            Conversation()
                .environment(\.chatAvailableWidth, geometry.size.width - ChatBubbleLayout.screenMargin * 2)
        }
    }

    //MARK: - Conversation

    private func Conversation() -> some View {
        ZStack {
            VStack {
                ScrollView {
                    ScrollViewReader { proxy in
                        ZStack {
                            VStack(spacing: 0) {
                                ForEach(messageVM.formattedMessages) { message in
                                    MessageView(message: message) {
                                        messageVM.repliedMessage = message
                                        isFocused = true
                                    } tappedRepliedMessage: {
                                        if let repliedMessageId = message.repliedMessageId {
                                            scrollToMessage(withId: repliedMessageId, usingProxy: proxy)
                                            highlightMessage(withId: repliedMessageId)
                                        }
                                    } resendMessage: {
                                        Task {
                                            try await resendMessage(withId: message.id)
                                        }
                                    }
                                    .background(messageVM.highlightedMessageId == message.id ? Color.gray.opacity(0.5) : Color.clear)
                                    .contextMenu {
                                        MessageMenu(forMessage: message)
                                    }
                                }
                                .onAppear {
                                    if let lastMessageId = messageVM.formattedMessages.last?.id {
                                        scrollToMessage(withId: lastMessageId, usingProxy: proxy, animated: false)
                                    }
                                }
                                .onChange(of: messageVM.lastMessageAdded) { _ in
                                    if let id = messageVM.lastMessageAdded {
                                        scrollToMessage(withId: id, usingProxy: proxy)
                                    }
                                }
                                .onChange(of: isFocused) { _ in
                                    if isFocused {
                                        if let lastMessageId = messageVM.formattedMessages.last?.id {
                                            scrollToMessage(withId: lastMessageId, usingProxy: proxy)
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                scrollToMessage(withId: lastMessageId, usingProxy: proxy)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, ChatBubbleLayout.screenMargin)
                        }
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                .refreshable {
                    hapticFeedback(style: .soft)
                    Task {
                        try await getMessages(.oldest)
                    }
                }
                
                VStack {
                    LockedView()
                    
                    MessageComposer()
                }
            }
        }
        .onAppear {
            // Os listeners entram antes da requisição: se uma mensagem chegar enquanto o
            // histórico carrega, ela é mesclada em vez de se perder na janela entre as duas.
            listenToMessages()
            listenToDeletedMessages()
            Task {
                try await getMessages(.newest)
            }
            updateBadge()
            NotificationManager.removeDeliveredNotifications(forChatId: chatId)
        }
        .onDisappear {
            stopListeningMessages()
            updateBadge()
        }
        .onChange(of: socket.resyncSignal) { _ in
            // Conexão nova, novo registro do usuário ou volta do background: reconcilia a
            // conversa aberta com a API para recuperar o que possa ter passado batido.
            Task {
                try await getMessages(.resync)
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                UserHeader()
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                SocketStatusView()
            }
        }
        .fullScreenCover(isPresented: $messageVM.isCameraDisplayed) {
            CameraView { image in
                Task {
                    let token = try await authVM.getFirebaseToken()
                    try await messageVM.sendImage(forChat: self.chatId, image: image, token: token)
                }
            }
        }
        .sheet(isPresented: $messageVM.isPhotosDisplayed) {
            MultiplePhotosPicker(selectedPhotos: $messageVM.images)
        }
    }
    
    //MARK: - User Header
    
    @ViewBuilder
    private func UserHeader() -> some View {
        HStack {
            ProfilePicView(profilePic: chatPic, size: 32)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(username)
                    .font(.callout)
                    .fontWeight(.bold)
                    .foregroundStyle(.gray)
                
                Image(systemName: "chevron.right")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 8, height: 8)
                    .foregroundStyle(.gray)
            }
        }
        .padding(.bottom, 6)
        .onTapGesture {
            navCoordinator.navigate(to: .userProfile(self.otherUserUid))
        }
    }
    
    //MARK: - Message Menu
    
    @ViewBuilder
    private func MessageMenu(forMessage message: FormattedMessage) -> some View {
        if let text = message.message {
            Button {
                let pasteboard = UIPasteboard.general
                pasteboard.string = text
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
            
            Button {
                messageVM.repliedMessage = message
                isFocused = true
            } label: {
                Label("Reply", systemImage: "arrowshape.turn.up.left")
            }
        }
        
        if message.message != nil && message.isCurrentUser {
            Divider()
        }
        
        if message.isCurrentUser && getElapsedTimeSinceMessage(message) < Constants.MAX_ELAPSED_TIME_DELETE_MESSAGE_SECONDS {
            Button(role: .destructive) {
                Task {
                    let token = try await authVM.getFirebaseToken()
                    await messageVM.deleteMessage(messageId: message.id, token: token)
                }
            } label: {
                Image(systemName: "arrow.uturn.backward.circle")
                Text("Undo Send")
            }
        }
    }
    
    // MARK: - Locked View
    
    @ViewBuilder
    private func LockedView() -> some View {
        if shouldDisplayLockedView() {
            Divider()
            
            LockedChatView(username: self.username)
        }
    }
    
    //MARK: - Message Composer
    
    @ViewBuilder
    private func MessageComposer() -> some View {
        VStack {
            Reply()
            
            Attachment()
            
            if shouldDisplayMessageComposer() {
                HStack(spacing: 8) {
                    if shouldDisplayPlusButton() {
                        Plus()
                    }
                    
                    TextField("Write a message...", text: $messageVM.messageText, axis: .vertical)
                        .padding(10)
                        .background(LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                        .cornerRadius(20)
                        .shadow(color: .gray, radius: 10)
                        .focused($isFocused)
                    
                    if shouldDisplaySendButton() {
                        Button {
                            Task {
                                let token = try await authVM.getFirebaseToken()
                                try await messageVM.sendMessage(
                                    forChat: chatId,
                                    text: messageVM.messageText.nonEmptyOrNil(),
                                    images: messageVM.images,
                                    repliedMessage: messageVM.repliedMessage,
                                    token: token
                                )
                                updateChatLockedStatus()
                            }
                        } label: {
                            Image(systemName: "paperplane.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 24)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    //MARK: - Reply
    
    @ViewBuilder
    private func Reply() -> some View {
        if let repliedMessage = messageVM.repliedMessage {
            HStack {
                VStack(alignment: .leading) {
                    Text(repliedMessage.isCurrentUser ? "You" : username)
                        .font(.subheadline)
                    
                    if let repliedMessageText = repliedMessage.message {
                        Text(repliedMessageText)
                            .foregroundStyle(.gray)
                            .lineLimit(2)
                    } else if repliedMessage.imageUrl != nil {
                        Label("Image", systemImage: "photo")
                            .foregroundStyle(.gray)
                    }
                }
                
                Spacer()
                
                Image(systemName: "xmark.circle")
                    .foregroundStyle(.blue)
                    .onTapGesture {
                        messageVM.repliedMessage = nil
                    }
            }
            .padding(10)
        }
    }
    
    //MARK: - Attachment
    
    @ViewBuilder
    private func Attachment() -> some View {
        if !messageVM.images.isEmpty {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(Array(messageVM.images.enumerated()), id: \.offset) { index, image in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 100)
                                .cornerRadius(8)
                            
                            Button {
                                messageVM.removeImage(fromIndex: index)
                            } label: {
                                RemoveMediaButton(size: .small)
                            }
                            .padding([.top, .trailing], 2)
                        }
                    }
                }
            }
        }
    }
    
    //MARK: - Plus
    
    @ViewBuilder
    private func Plus() -> some View {
        Menu {
            Button {
                messageVM.isCameraDisplayed = true
            } label: {
                Label("Camera", systemImage: "camera")
            }
            
            Button {
                messageVM.isPhotosDisplayed = true
            } label: {
                Label("Photos", systemImage: "photo")
            }
            
        } label: {
            Image(systemName: "plus")
                .foregroundStyle(.gray)
                .padding(12)
                .background(
                    Circle().fill(.thinMaterial)
                )
        }
    }
    
    //MARK: - Private Method
    
    private func listenToMessages() {
        socket.addListener(for: "message", owner: messageVM.listenerOwner) { data, ack in
            messageVM.processMessage(data, toChat: chatId) { messageId in
                emitReadCommand(forMessage: messageId)
            }
            updateChatLockedStatus()
        }
    }


    private func listenToDeletedMessages() {
        socket.addListener(for: "message-delete", owner: messageVM.listenerOwner) { data, ack in
            if let messageId = data.first as? String {
                RealtimeLog.eventReceived("message-delete", chatId: chatId)
                messageVM.removeMessage(withId: messageId)
            } else {
                RealtimeLog.eventIgnored("message-delete", reason: "id ausente no payload")
            }
        }
    }


    private func emitReadCommand(forMessage messageId: String) {
        socket.socket?.emit("read", messageId)
    }

    /// Remove só os listeners desta tela.
    ///
    /// Antes era um `socket.off("message")` global, que derrubava também o listener de uma
    /// outra conversa ainda aberta — por exemplo ao fechar um chat aberto por notificação
    /// sobre a conversa que estava na pilha. A conversa de baixo ficava viva na tela, mas
    /// muda: só voltava a receber mensagens se o usuário saísse e entrasse de novo.
    private func stopListeningMessages() {
        socket.removeListeners(owner: messageVM.listenerOwner)
    }

    private func updateBadge() {
        NotificationCenter.default.post(name: .updateBadge, object: nil)
    }
    
    enum FetchMessageType {
        case newest
        case oldest
        case resync
    }

    private func getMessages(_ type: FetchMessageType) async throws {
        let token = try await authVM.getFirebaseToken()
        switch type {
        case .newest:
            await messageVM.getLastMessages(chatId: chatId, token: token)
        case .oldest:
            await messageVM.getMessages(chatId: chatId, token: token)
        case .resync:
            await messageVM.getLastMessages(chatId: chatId, token: token, source: "resync")
        }
    }
    
    private func scrollToMessage(withId messageId: String, usingProxy proxy: ScrollViewProxy, animated: Bool = true) {
        if animated {
            withAnimation {
                proxy.scrollTo(messageId, anchor: .top)
            }
        } else {
            proxy.scrollTo(messageId, anchor: .top)
        }
        
    }
    
    private func highlightMessage(withId messageId: String) {
        messageVM.highlightedMessageId = messageId
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                messageVM.highlightedMessageId = nil
            }
        }
    }
    
    private func resendMessage(withId messageId: String) async throws {
        let token = try await authVM.getFirebaseToken()
        await messageVM.resendMessage(withTempId: messageId, token: token)
        updateChatLockedStatus()
    }
    
    private func shouldDisplayLockedView() -> Bool {
        return isLocked && !didOtherUserSendMessage()
    }
    
    private func shouldDisplayMessageComposer() -> Bool {
        return !(self.isLocked && didISendMessage() && !didOtherUserSendMessage())
    }
    
    private func didISendMessage() -> Bool {
        return messageVM.formattedMessages.contains { $0.isCurrentUser }
    }
    
    private func didOtherUserSendMessage() -> Bool {
        return messageVM.formattedMessages.contains { $0.isCurrentUser == false }
    }
    
    private func shouldDisplayPlusButton() -> Bool {
        return !(self.isLocked && messageVM.formattedMessages.isEmpty)
    }
    
    private func shouldDisplaySendButton() -> Bool {
        return !(messageVM.messageText.isEmpty && messageVM.images.isEmpty)
    }
    
    private func updateChatLockedStatus() {
        print("⚠️ updateChatLockedStatus")
        if isLocked && didISendMessage() && didOtherUserSendMessage() {
            self.isLocked = false
        }
    }
    
    private func getElapsedTimeSinceMessage(_ message: FormattedMessage) -> Int {
        let now = Int(Date().timeIntervalSince1970)
        return now - message.createdAt.timeIntervalSince1970InSeconds
    }
}

//#Preview {
//    MessageScreen(chatId: "", username: "ordozgoite", otherUserUid: "", chatPic: nil)
//}
