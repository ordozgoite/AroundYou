//
//  MessageScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 27/03/24.
//

import SwiftUI
import PhotosUI

struct MessageScreen: View {
    
    let chatId: String
    let username: String
    let otherUserUid: String
    let chatPic: String?
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var messageVM = MessageViewModel()
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
                                }
                                .onAppear {
                                    if let lastMessageId = messageVM.formattedMessages.last?.id {
                                        scrollToMessage(withId: lastMessageId, usingProxy: proxy, animated: false)
                                    }
                                }
                                .onChange(of: messageVM.formattedMessages) { _ in
                                    if let lastMessageId = messageVM.formattedMessages.last?.id {
                                        scrollToMessage(withId: lastMessageId, usingProxy: proxy)
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
                
                MessageComposer()
            }
        }
        .onAppear {
            manageSocket()
            Task {
                try await updateMessages()
            }
        }
        //        .onDisappear {
        //            stopUpdatingMessages()
        //        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                NavigationLink(destination: UserProfileScreen(userUid: otherUserUid)) {
                    UserHeader()
                }
            }
        }
        .fullScreenCover(isPresented: $messageVM.isCameraDisplayed) {
            CameraView(image: $messageVM.image)
        }
        .sheet(isPresented: $messageVM.isPhotosDisplayed) {
            ImagePicker(selectedImage: $messageVM.image)
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
    
    //MARK: - Message Composer
    
    @ViewBuilder
    private func MessageComposer() -> some View {
        VStack {
            Reply()
            
            Attachment()
            
            HStack(spacing: 8) {
                Plus()
                
                TextField("Write a message...", text: $messageVM.messageText, axis: .vertical)
                    .padding(10)
                    .background(LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                    .cornerRadius(20)
                    .shadow(color: .gray, radius: 10)
                    .focused($isFocused)
                
                if !messageVM.messageText.isEmpty || messageVM.image != nil {
                    Button {
                        Task {
                            let token = try await authVM.getFirebaseToken()
                            try await messageVM.sendMessage(
                                chatId: chatId,
                                text: messageVM.messageText.nonEmptyOrNil(),
                                image: messageVM.image,
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
        if let selectedImage =  messageVM.image {
            HStack {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 64)
                        .cornerRadius(8)
                        .padding()
                    
                    Button {
                        messageVM.image = nil
                    } label: {
                        Image(systemName: "x.circle.fill")
                    }
                }
                
                Spacer()
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
    
    private func manageSocket() {
        print("🛜 SOCKET!")
        
        SocketService.shared.connect()
        
        messageVM.socket.emit("join-room", chatId)
        
        messageVM.socket.on("message") { data, ack in
            messageVM.displayMessage(fromData: data)
        }
    }
    
    //    private func startUpdatingMessages() {
    //        messageVM.messageTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
    //            Task {
    //                try await updateMessages()
    //            }
    //        }
    //        messageVM.messageTimer?.fire()
    //    }
    
    private func updateMessages() async throws {
        let token = try await authVM.getFirebaseToken()
        await messageVM.getMessages(chatId: chatId, token: token)
    }
    
    //    private func stopUpdatingMessages() {
    //        messageVM.messageTimer?.invalidate()
    //    }
    
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
