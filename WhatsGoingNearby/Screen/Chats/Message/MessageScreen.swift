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
    @StateObject private var swipeDriver = ChatSwipeDriver()
    @StateObject private var historyAnchor = ChatHistoryScrollAnchor()
    @FocusState private var isFocused: Bool
    /// Distingue o teclado aberto por uma resposta do teclado aberto por um toque no campo.
    @State private var suppressesScrollOnNextFocus = false
    @State private var didPerformInitialScroll = false
    
    var body: some View {
        // A largura máxima das bolhas é derivada da largura real do container, e não de
        // um valor fixo, para acompanhar os diferentes tamanhos de iPhone.
        GeometryReader { geometry in
            Conversation()
                .environment(\.chatAvailableWidth, geometry.size.width - ChatBubbleLayout.screenMargin * 2)
                .environment(\.chatSwipeDriver, swipeDriver)
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
                                OlderMessagesLoader()

                                ForEach(messageVM.formattedMessages) { message in
                                    MessageView(message: message, otherUsername: username, chatPic: chatPic) {
                                        startReply(to: message)
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
                            }
                            .padding(.horizontal, ChatBubbleLayout.screenMargin)
                            // Estes observadores ficam no VStack, e não no ForEach: ali eles
                            // eram registrados uma vez por linha, e o `onAppear` que levava a
                            // conversa para o fim voltaria a disparar a cada linha antiga
                            // inserida, desfazendo a paginação.
                            .onChange(of: messageVM.formattedMessages.count) { _ in
                                positionAtLatestMessageOnce(usingProxy: proxy)
                            }
                            .onChange(of: messageVM.lastMessageAdded) { _ in
                                if let id = messageVM.lastMessageAdded {
                                    scrollToMessage(withId: id, usingProxy: proxy)
                                }
                            }
                            .onChange(of: isFocused) { _ in
                                guard isFocused else {
                                    suppressesScrollOnNextFocus = false
                                    return
                                }
                                // Responder também abre o teclado, mas ali o usuário está
                                // olhando justamente a mensagem que citou: levar a conversa
                                // para o fim tiraria ela da tela.
                                guard !suppressesScrollOnNextFocus else {
                                    suppressesScrollOnNextFocus = false
                                    return
                                }
                                if let lastMessageId = messageVM.formattedMessages.last?.id {
                                    scrollToMessage(withId: lastMessageId, usingProxy: proxy)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        scrollToMessage(withId: lastMessageId, usingProxy: proxy)
                                    }
                                }
                            }
                            // Precisam estar dentro do ScrollView: é daqui que ambos sobem
                            // a hierarquia até o UIScrollView da conversa.
                            .background(ChatSwipeInstaller(driver: swipeDriver))
                            .background(ChatHistoryAnchorInstaller(anchor: historyAnchor))
                        }
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: historyAnchor.isApproachingTop) { isApproachingTop in
                    guard isApproachingTop else { return }
                    loadOlderMessagesIfNeeded()
                }


                VStack {
                    LockedView()
                    
                    MessageComposer()
                }
            }
        }
        .onAppear {
            // A âncora precisa fotografar a rolagem no mesmo ciclo da inserção, então ela é
            // avisada de dentro do view model e não daqui.
            // Captura fraca e sem `self`: o view model guarda este closure, e capturar a
            // View traria o próprio view model de volta num ciclo.
            messageVM.willPrependOlderMessages = { [weak historyAnchor] in
                historyAnchor?.captureBeforePrepend()
            }
            // O que já está em cache aparece antes de tudo; a requisição abaixo só
            // reconcilia o que mudou.
            messageVM.loadCachedMessages(chatId: chatId)
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
    
    //MARK: - Older Messages Loader

    /// Indicador discreto do histórico chegando, e sentinela da posição da rolagem.
    ///
    /// A altura é fixa mesmo parado: se o indicador entrasse e saísse do layout, o conteúdo
    /// mudaria de altura no meio da paginação e brigaria com a âncora que segura a posição.
    @ViewBuilder
    private func OlderMessagesLoader() -> some View {
        ZStack {
            if messageVM.isLoadingOlderMessages {
                ProgressView()
                    .scaleEffect(0.7)
            }
        }
        .frame(height: 28)
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
                startReply(to: message)
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
                            // Se o usuário estava ditando, o trecho reconhecido ainda é
                            // provisório: confirmar a composição aqui é o que faz o campo
                            // — e não o `@Published`, que pode estar atrás — devolver a
                            // mensagem final.
                            let composedText = isFocused ? TextInputComposition.finishComposition() : nil
                            let text = (composedText ?? messageVM.messageText).nonEmptyOrNil()
                            let images = messageVM.images
                            let repliedMessage = messageVM.repliedMessage

                            Task {
                                let token = try await authVM.getFirebaseToken()
                                try await messageVM.sendMessage(
                                    forChat: chatId,
                                    text: text,
                                    images: images,
                                    repliedMessage: repliedMessage,
                                    token: token
                                )
                                // `sendMessage` zera o estado; isto garante que o conteúdo
                                // real do campo também sumiu, sem depender de o UIKit
                                // aceitar a escrita vinda do binding.
                                TextInputComposition.clearActiveInput()
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
    
    /// Mesma prévia usada dentro da bolha, para que preparar a resposta e lê-la depois na
    /// conversa tenham a mesma linguagem visual.
    @ViewBuilder
    private func Reply() -> some View {
        if let repliedMessage = messageVM.repliedMessage {
            HStack(spacing: 12) {
                QuotedMessageView(
                    quoted: QuotedMessage(
                        author: repliedMessage.isCurrentUser ? "You" : username,
                        text: repliedMessage.message ?? "📷 Photo"
                    ),
                    tone: .onNeutral
                )

                Spacer(minLength: 0)

                Button {
                    messageVM.repliedMessage = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.gray)
                }
            }
            .padding(.vertical, 6)
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

    /// Busca a página anterior quando a rolagem se aproxima do começo do que já está
    /// carregado, sem esperar o usuário encostar no topo.
    private func loadOlderMessagesIfNeeded() {
        // A reserva é síncrona de propósito: a proximidade do topo é reavaliada a cada
        // quadro da rolagem.
        guard messageVM.beginLoadingOlderMessages() else { return }

        Task {
            do {
                let token = try await authVM.getFirebaseToken()
                await messageVM.loadOlderMessages(chatId: chatId, token: token)
            } catch {
                messageVM.cancelLoadingOlderMessages()
            }
        }
    }

    /// Leva a conversa para o fim quando a primeira leva de mensagens chega, uma única vez.
    private func positionAtLatestMessageOnce(usingProxy proxy: ScrollViewProxy) {
        guard !didPerformInitialScroll, let lastMessageId = messageVM.formattedMessages.last?.id else { return }
        didPerformInitialScroll = true
        scrollToMessage(withId: lastMessageId, usingProxy: proxy, animated: false)

        // A prefetch só vale depois de posicionar no fim: até lá o topo do conteúdo está
        // dentro da viewport e dispararia uma busca sem o usuário ter rolado nada.
        DispatchQueue.main.async { historyAnchor.isPrefetchEnabled = true }
    }

    /// Abre o composer citando uma mensagem, sem levar a conversa para o fim.
    ///
    /// O sinalizador só vale para o próximo evento de foco. Com o teclado já aberto não há
    /// evento nenhum, e marcá-lo ali deixaria o próximo toque no campo sem rolagem.
    private func startReply(to message: FormattedMessage) {
        suppressesScrollOnNextFocus = !isFocused
        messageVM.repliedMessage = message
        isFocused = true
    }


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
        case resync
    }

    private func getMessages(_ type: FetchMessageType) async throws {
        let token = try await authVM.getFirebaseToken()
        switch type {
        case .newest:
            await messageVM.getLastMessages(chatId: chatId, token: token)
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
