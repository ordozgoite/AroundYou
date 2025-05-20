//
//  CommunityMessageScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 18/02/25.
//

import SwiftUI

struct CommunityMessageScreen: View {
    
    var community: FormattedCommunity
    @Binding var isViewDisplayed: Bool
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var communityMessageVM = CommunityMessageViewModel()
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var socket: SocketService
    @Environment(\.presentationMode) var presentationMode
    @FocusState private var isFocused: Bool
    @Environment(\.dismiss) var dismiss
    
    let pub = NotificationCenter.default
        .publisher(for: .popCommunity)
    
    let refreshCommunities: () -> ()
    
    var body: some View {
        ZStack {
            VStack {
                ScrollView {
                    ScrollViewReader { proxy in
                        ZStack {
                            VStack(spacing: 0) {
                                ForEach(communityMessageVM.formattedMessages) { message in
                                    if message.id == Constants.communityDiscaimerMessageId {
                                        Disclaimer()
                                    } else {
                                        CommunityMessageView(message: message) {
                                            communityMessageVM.repliedMessage = message
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
                                        .background(communityMessageVM.highlightedMessageId == message.id ? Color.gray.opacity(0.5) : Color.clear)
                                        .contextMenu {
                                            MessageMenu(forMessage: message)
                                        }
                                    }
                                }
                                .onAppear {
                                    if let lastMessageId = communityMessageVM.formattedMessages.last?.id {
                                        scrollToMessage(withId: lastMessageId, usingProxy: proxy, animated: false)
                                    }
                                }
                                .onChange(of: communityMessageVM.lastMessageAdded) { _ in
                                    if let id = communityMessageVM.lastMessageAdded {
                                        scrollToMessage(withId: id, usingProxy: proxy)
                                    }
                                }
                                .onChange(of: isFocused) { _ in
                                    if isFocused {
                                        if let lastMessageId = communityMessageVM.formattedMessages.last?.id {
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
            
            AYErrorAlert(message: communityMessageVM.overlayError.1 , isErrorAlertPresented: $communityMessageVM.overlayError.0)
        }
        .onAppear {
            Task {
                try await getMessages(.newest)
            }
            listenToMessages()
            updateBadge()
        }
        .onReceive(pub) { (output) in
            self.dismissScreenAndRefreshCommunities()
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
    private func MessageMenu(forMessage message: FormattedCommunityMessage) -> some View {
        Button {
            let pasteboard = UIPasteboard.general
            pasteboard.string = message.text
        } label: {
            Label("Copy", systemImage: "doc.on.doc")
        }
        
        Button {
            communityMessageVM.repliedMessage = message
            isFocused = true
        } label: {
            Label("Reply", systemImage: "arrowshape.turn.up.left")
        }
        
        if message.isCurrentUser {
            Divider()
        }
        
        if message.isCurrentUser && getElapsedTimeSinceMessage(message) < Constants.MAX_ELAPSED_TIME_DELETE_MESSAGE_SECONDS {
            Button(role: .destructive) {
                Task {
                    let token = try await authVM.getFirebaseToken()
                    await communityMessageVM.deleteMessage(messageId: message.id, token: token)
                }
            } label: {
                Image(systemName: "arrow.uturn.backward.circle")
                Text("Undo Send")
            }
        }
    }
    
    // MARK: - Disclaimer
    
    @ViewBuilder
    private func Disclaimer() -> some View {
        HStack(alignment: .bottom) {
            // info icon
            Image(systemName: "info.circle")
                .resizable()
                .foregroundStyle(.gray)
                .frame(width: 32, height: 32)
            
            // Text bubble
            Text("Only people nearby this community can interact with it, including the owner.")
                .italic()
                .foregroundStyle(.gray)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(
                    Color(uiColor: .secondarySystemBackground),
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                )
                .background(alignment: .bottomLeading) {
                    Image("incomingTail")
                        .renderingMode(.template)
                        .foregroundStyle(Color(uiColor: .secondarySystemBackground))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(.trailing, 64)
                .padding(.bottom, 8)
        }
    }
    
    //MARK: - Message Composer
    
    @ViewBuilder
    private func MessageComposer() -> some View {
        VStack {
            Reply()
            
            HStack(spacing: 8) {
                TextField("Write a message...", text: $communityMessageVM.messageText, axis: .vertical)
                    .padding(10)
                    .background(LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                    .cornerRadius(20)
                    .shadow(color: .gray, radius: 10)
                    .focused($isFocused)
                
                if shouldDisplaySendButton() {
                    Button {
                        Task {
                            try await sendMessage()
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
        if let repliedMessage = communityMessageVM.repliedMessage {
            HStack {
                VStack(alignment: .leading) {
                    Text(repliedMessage.senderUsername)
                        .font(.subheadline)
                    
                    Text(repliedMessage.text)
                        .foregroundStyle(.gray)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "xmark.circle")
                    .foregroundStyle(.blue)
                    .onTapGesture {
                        communityMessageVM.repliedMessage = nil
                    }
            }
            .padding(10)
        }
    }
    
    //MARK: - Private Method
    
    //    private func startLocationTimer() {
    //        Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
    //            if let location = locationManager.location {
    //                communityMessageVM.latitude = location.coordinate.latitude
    //                communityMessageVM.longitude = location.coordinate.longitude
    //            }
    //        }
    //    }
    
    private func listenToMessages() {
        socket.socket?.on("communityMessage") { data, ack in
            if let message = data as? [Any] {
                print("📩 Received message: \(message)")
                communityMessageVM.processSocketMessage(message, toChat: community.id) { messageId in
                    emitReadCommand(forMessage: messageId)
                }
            }
        }
    }
    
    private func sendMessage() async throws {
        locationManager.requestLocation()
        if let location = locationManager.location {
            let token = try await authVM.getFirebaseToken()
            
            let currentLocation = Location(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            
            await communityMessageVM.sendMessage(forCommunityId: self.community.id, text: communityMessageVM.messageText, repliedMessage: communityMessageVM.repliedMessage, location: currentLocation, token: token)
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
        let token = try await authVM.getFirebaseToken()
        switch type {
        case .newest:
            await communityMessageVM.getLastMessages(communityId: self.community.id, token: token)
        case .oldest:
            await communityMessageVM.getMessages(communityId: self.community.id, token: token)
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
        communityMessageVM.highlightedMessageId = messageId
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                communityMessageVM.highlightedMessageId = nil
            }
        }
    }
    
    private func resendMessage(withId messageId: String) async throws {
        locationManager.requestLocation()
        if let location = locationManager.location {
            let token = try await authVM.getFirebaseToken()
            
            let currentLocation = Location(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            
            await communityMessageVM.resendMessage(withTempId: messageId, location: currentLocation, token: token)
        }
    }
    
    private func shouldDisplaySendButton() -> Bool {
        return !communityMessageVM.messageText.isEmpty
    }
    
    private func getElapsedTimeSinceMessage(_ message: FormattedCommunityMessage) -> Int {
        let now = Int(Date().timeIntervalSince1970)
        return now - message.createdAt.timeIntervalSince1970InSeconds
    }
    
    private func dismissScreenAndRefreshCommunities() {
        refreshCommunities()
        dismiss()
    }
}

#Preview {
    //    CommunityMessageScreen(communityId: <#String#>, communityName: <#String#>, communityImageUrl: <#String?#>, socket: <#SocketService#>)
}
