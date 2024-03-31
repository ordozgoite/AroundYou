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
                                MessageView(message: message)
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
                                        } else {
                                            Button {
                                                messageVM.repliedMessage = message
                                                isFocused = true
                                            } label: {
                                                Image(systemName: "arrowshape.turn.up.left")
                                                Text("Reply Message")
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
//                            .onChange(of: isFocused) { isFoc in
//                                if isFoc {
//                                    withAnimation {
//                                        proxy.scrollTo(messageVM.messages.last!.id, anchor: .top)
//                                    }
//                                }
//                            }
                        }
                        .padding(.horizontal, 10)
                        
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            
            MessageComposer()
        }
        .onAppear {
            SocketService.shared.connect()
            
            messageVM.socket.emit("join-room", chatId)
            
            messageVM.socket.on("message") { dataArray, ack in
                messageVM.decodeMessages(message: dataArray)
            }
            Task {
                let token = try await authVM.getFirebaseToken()
                await messageVM.getMessages(chatId: chatId, token: token)
            }
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
    
    //MARK: - MessageComposer
    
    @ViewBuilder
    private func MessageComposer() -> some View {
        VStack {
            if let repliedMessage = messageVM.repliedMessage {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Replying to:")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                        
                        Image(systemName: "xmark")
                            .scaleEffect(0.8)
                            .foregroundStyle(.blue)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onTapGesture {
                        messageVM.repliedMessage = nil
                    }
                    
                    Text(repliedMessage.message)
                        .foregroundStyle(.gray)
                        .lineLimit(2)
                }
                .padding(10)
            }
            
            HStack(spacing: 16) {
                //            Image(systemName: "plus")
                //                .foregroundStyle(.gray)
                //                .background(
                //                    Circle()
                //                        .fill(.gray.opacity(0.1))
                //                        .frame(width: 40, height: 40, alignment: .center)
                //                )
                
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
}

//#Preview {
//    MessageScreen()
//}