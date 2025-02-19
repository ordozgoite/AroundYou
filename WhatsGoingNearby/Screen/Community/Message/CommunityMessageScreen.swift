//
//  CommunityMessageScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 18/02/25.
//

import SwiftUI

struct CommunityMessageScreen: View {
    
    var community: FormattedCommunity
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var messageVM = MessageViewModel()
    @ObservedObject var socket: SocketService
    @Environment(\.presentationMode) var presentationMode
    @FocusState private var isFocused: Bool
    
    var body: some View {
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
                            .padding(.horizontal, 10)
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
                
                MessageComposer()
            }
        }
        .onAppear {
            Task {
                try await getMessages(.newest)
            }
            listenToMessages()
            updateBadge()
        }
        .onDisappear {
            stopListeningMessages()
            updateBadge()
        }
        .onChange(of: socket.status) { status in
            if status == .connected {
                Task {
                    try await getMessages(.newest)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                NavigationLink {
                    CommunityDetailScreen(community: community)
                        .environmentObject(authVM)
                } label: {
                    CommunityHeader()
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                SocketStatusView(socket: socket)
            }
        }
    }
    
    //MARK: - Community Header
    
    @ViewBuilder
    private func CommunityHeader() -> some View {
        HStack {
            CommunityImageView(imageUrl: community.imageUrl, size: 32)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(community.name)
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
    
    //MARK: - Message Composer
    
    @ViewBuilder
    private func MessageComposer() -> some View {
        VStack {
            //            Reply()
            
            HStack(spacing: 8) {
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
                                forChat: community.id,
                                text: messageVM.messageText.nonEmptyOrNil(),
                                images: messageVM.images,
                                repliedMessage: messageVM.repliedMessage,
                                token: token
                            )
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
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    //MARK: - Reply
    
    //    @ViewBuilder
    //    private func Reply() -> some View {
    //        if let repliedMessage = messageVM.repliedMessage {
    //            HStack {
    //                VStack(alignment: .leading) {
    //                    Text(repliedMessage.isCurrentUser ? "You" : username)
    //                        .font(.subheadline)
    //
    //                    if let repliedMessageText = repliedMessage.message {
    //                        Text(repliedMessageText)
    //                            .foregroundStyle(.gray)
    //                            .lineLimit(2)
    //                    } else if repliedMessage.imageUrl != nil {
    //                        Label("Image", systemImage: "photo")
    //                            .foregroundStyle(.gray)
    //                    }
    //                }
    //
    //                Spacer()
    //
    //                Image(systemName: "xmark.circle")
    //                    .foregroundStyle(.blue)
    //                    .onTapGesture {
    //                        messageVM.repliedMessage = nil
    //                    }
    //            }
    //            .padding(10)
    //        }
    //    }
    
    //MARK: - Private Method
    
    private func listenToMessages() {
        socket.socket?.on("message") { data, ack in
            if let message = data as? [Any] {
                print("📩 Received message: \(message)")
                messageVM.processMessage(message, toChat: community.id) { messageId in
                    emitReadCommand(forMessage: messageId)
                }
            }
        }
    }
    
    private func emitReadCommand(forMessage messageId: String) {
        socket.socket?.emit("read", messageId)
    }
    
    private func stopListeningMessages() {
        socket.socket?.off("message")
    }
    
    private func updateBadge() {
        NotificationCenter.default.post(name: .updateBadge, object: nil)
    }
    
    enum FetchMessageType {
        case newest
        case oldest
    }
    
    private func getMessages(_ type: FetchMessageType) async throws {
        //        let token = try await authVM.getFirebaseToken()
        //        switch type {
        //        case .newest:
        //                        await messageVM.getLastMessages(chatId: chatId, token: token)
        //        case .oldest:
        //                        await messageVM.getMessages(chatId: chatId, token: token)
        //        }
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
    }
    
    private func shouldDisplaySendButton() -> Bool {
        return !messageVM.messageText.isEmpty
    }
    
    private func getElapsedTimeSinceMessage(_ message: FormattedMessage) -> Int {
        let now = Int(Date().timeIntervalSince1970)
        return now - message.createdAt.timeIntervalSince1970InSeconds
    }
}

#Preview {
    //    CommunityMessageScreen(communityId: <#String#>, communityName: <#String#>, communityImageUrl: <#String?#>, socket: <#SocketService#>)
}
