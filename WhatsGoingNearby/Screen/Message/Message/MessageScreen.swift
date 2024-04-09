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
                                    if !messageVM.messages.isEmpty {
                                        proxy.scrollTo(messageVM.messages.last!.id, anchor: .top)
                                    }
                                }
                                .onChange(of: messageVM.messages) { _ in
                                    if !messageVM.messages.isEmpty {
                                        withAnimation {
                                            proxy.scrollTo(messageVM.messages.last!.id, anchor: .top)
                                        }
                                    }
                                }
                                .onChange(of: isFocused) { _ in
                                    if isFocused {
                                        
                                        if !messageVM.messages.isEmpty {
                                            withAnimation {
                                                proxy.scrollTo(messageVM.messages.last!.id, anchor: .top)
                                            }
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                withAnimation {
                                                    proxy.scrollTo(messageVM.messages.last!.id, anchor: .top)
                                                }
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
                            await messageVM.sendMessage(chatId: chatId, text: messageVM.messageText.isEmpty ? nil : messageVM.messageText, image: messageVM.image, repliedMessageId: messageVM.repliedMessage?.id, token: token)
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
                
                if let repliedMessageText = repliedMessage.message {
                    Text(repliedMessageText)
                        .foregroundStyle(.gray)
                        .lineLimit(2)
                } else if let repliedMessageText = repliedMessage.imageUrl {
                    Label("Image", systemImage: "photo")
                        .foregroundStyle(.gray)
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
//    MessageScreen(chatId: "", username: "ordozgoite", otherUserUid: "", chatPic: nil)
//}
