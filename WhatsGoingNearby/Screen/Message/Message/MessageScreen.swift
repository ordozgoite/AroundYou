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
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var messageVM = MessageViewModel()
    @Environment(\.presentationMode) var presentationMode
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack {
            Header()
            
            ScrollView {
                ScrollViewReader { proxy in
                    VStack(spacing: 0) {
                        ForEach(messageVM.messages) { message in
                            MessageView(message: message)
                        }
                    }
                    .padding()
                    .onChange(of: messageVM.messages.count) { _ in
                            withAnimation {
                                proxy.scrollTo(messageVM.messages.count - 1)
                            }
                    }
                }
            }
            
            MessageComposer()
        }
        .onAppear {
            Task {
                let token = try await authVM.getFirebaseToken()
                await messageVM.getMessages(chatId: chatId, token: token)
            }
        }
        
        .navigationBarBackButtonHidden()
    }
    
    //MARK: - Header
    
    @ViewBuilder
    private func Header() -> some View {
        HStack {
            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                Image(systemName: "chevron.left")
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundStyle(.gray)
                    .frame(width: 50, height: 50)
                
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
            
            Spacer()
        }
        .padding()
        .frame(width: screenWidth)
        .background(.thinMaterial)
    }
    
    //MARK: - MessageComposer
    
    @ViewBuilder
    private func MessageComposer() -> some View {
        HStack(spacing: 16) {
            Image(systemName: "plus")
                .foregroundStyle(.gray)
                .background(
                    Circle()
                        .fill(.gray.opacity(0.1))
                        .frame(width: 40, height: 40, alignment: .center)
                )
            
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
                        await messageVM.sendMessage(chatId: chatId, text: messageVM.messageText, token: token)
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
        .padding()
    }
}

//#Preview {
//    MessageScreen()
//}
