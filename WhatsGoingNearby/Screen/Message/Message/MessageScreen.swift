//
//  MessageScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 27/03/24.
//

import SwiftUI

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
        VStack {
            ScrollView {
                ScrollViewReader { proxy in
                    ZStack {
                        VStack(spacing: 0) {
                            ForEach(messageVM.messages) { message in
                                MessageView(message: message) { 
                                    messageVM.repliedMessage = message
                                    isFocused = true
                                }
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
                                proxy.scrollTo(messageVM.messages.last!.id, anchor: .top)
                            }
                            .onChange(of: messageVM.messages) { _ in
                                withAnimation {
                                    proxy.scrollTo(messageVM.messages.last!.id, anchor: .top)
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
        .onAppear {
            startUpdatingMessages()
        }
        .onDisappear {
            stopUpdatingMessages()
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                NavigationLink(destination: UserProfileScreen(userUid: otherUserUid)) {
                    UserHeader()
                }
            }
        }
    }
    
    //MARK: - User Header
    
    @ViewBuilder
    private func UserHeader() -> some View {
        HStack {
            ProfilePicView(profilePic: chatPic, size: 20)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(username)
                    .font(.caption)
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
            if let repliedMessage = messageVM.repliedMessage {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Replying to:")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                        
                        Spacer()
                        
                        Image(systemName: "xmark")
                            .scaleEffect(0.8)
                            .foregroundStyle(.blue)
                            .onTapGesture {
                                messageVM.repliedMessage = nil
                            }
                    }
                    
                    Text(repliedMessage.message)
                        .foregroundStyle(.gray)
                        .lineLimit(2)
                }
                .padding(10)
            }
            
            HStack(spacing: 16) {
                TextField("Write a message...", text: $messageVM.messageText, axis: .vertical)
                    .padding(10)
                    .background(LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                    .cornerRadius(20)
                    .shadow(color: .gray, radius: 10)
                    .focused($isFocused)
                
                if !messageVM.messageText.isEmpty {
                    Button {
                        Task {
                            let token = try await authVM.getFirebaseToken()
                            await messageVM.sendMessage(chatId: chatId, text: messageVM.messageText, repliedMessageId: messageVM.repliedMessage?.id, token: token)
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
        .padding()
    }
    
    //MARK: - Private Method
    
    private func startUpdatingMessages() {
        messageVM.messageTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task {
                try await updateMessages()
            }
        }
        messageVM.messageTimer?.fire()
    }
    
    private func updateMessages() async throws {
        let token = try await authVM.getFirebaseToken()
        await messageVM.getMessages(chatId: chatId, token: token)
    }
    
    private func stopUpdatingMessages() {
        messageVM.messageTimer?.invalidate()
    }
}

//#Preview {
//    MessageScreen()
//}
