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
    var isLocked: Bool
    
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
                
                VStack {
                    LockedView()
                    
                    MessageComposer()
                }
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
                NavigationLink(destination: UserProfileScreen(userUid: otherUserUid, socket: socket)) {
                    UserHeader()
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                SocketStatusView(socket: socket)
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
            PhotoPicker(selectedPhotos: $messageVM.images)
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
        
        if message.isCurrentUser {
            Button(role: .destructive) {
                Task {
                    let token = try await authVM.getFirebaseToken()
                    await messageVM.deleteMessage(messageId: message.id, token: token)
                }
            } label: {
                Image(systemName: "trash")
                Text("Delete Message")
            }
        }
    }
    
    // MARK: - Locked View
    
    @ViewBuilder
    private func LockedView() -> some View {
        if isLocked {
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
            
            if !(isLocked && !messageVM.formattedMessages.isEmpty) {
                HStack(spacing: 8) {
                    if !isLocked {
                        Plus()
                    }
                    
                    TextField("Write a message...", text: $messageVM.messageText, axis: .vertical)
                        .padding(10)
                        .background(LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                        .cornerRadius(20)
                        .shadow(color: .gray, radius: 10)
                        .focused($isFocused)
                    
                    if !messageVM.messageText.isEmpty || !messageVM.images.isEmpty {
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
                                print("📇 Index: \(index)")
                                messageVM.removeImage(fromIndex: index)
                            } label: {
                                Image(systemName: "x.circle")
                                    .foregroundStyle(.white)
                                    .background(Circle().fill(.gray))
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
        socket.socket?.on("message") { data, ack in
            if let message = data as? [Any] {
                print("📩 Received message: \(message)")
                messageVM.processMessage(message, toChat: chatId) { messageId in
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
        let name = Notification.Name(Constants.updateBadgeNotificationKey)
        NotificationCenter.default.post(name: name, object: nil)
    }
    
    enum FetchMessageType {
        case newest
        case oldest
    }
    
    private func getMessages(_ type: FetchMessageType) async throws {
        let token = try await authVM.getFirebaseToken()
        switch type {
        case .newest:
            await messageVM.getLastMessages(chatId: chatId, token: token)
        case .oldest:
            await messageVM.getMessages(chatId: chatId, token: token)
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
    }
}

//#Preview {
//    MessageScreen(chatId: "", username: "ordozgoite", otherUserUid: "", chatPic: nil)
//}
