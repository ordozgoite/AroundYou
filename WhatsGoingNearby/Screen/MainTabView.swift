//
//  MainTabView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import SwiftUI
import Kingfisher

struct MainTabView: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var socket = SocketService()
    @StateObject public var notificationManager = NotificationManager()
    @StateObject private var locationManager = LocationManager()
    @Environment(\.colorScheme) var colorScheme
    
    let pub = NotificationCenter.default
        .publisher(for: .updateBadge)
    
    @State private var selectedTab: Int = 0
    @State private var profileImage: UIImage?
    @State private var badgeTimer: Timer?
    @State private var unreadChats: Int?
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeScreen(locationManager: locationManager, socket: socket)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .environmentObject(authVM)
                .tag(0)
            
            ChatListScreen(socket: socket)
                .tabItem {
                    Label("Chats", systemImage: "bubble")
                }
                .environmentObject(authVM)
                .badge(unreadChats ?? 0)
                .tag(1)
            
            AccountScreen(locationManager: locationManager, socket: socket)
                .tabItem {
                    ProfileTabItemLabel()
                }
                .environmentObject(authVM)
                .tag(2)
        }
        .onAppear {
            Task {
                await loadProfileImage()
                updateBadge()
                listenToMessages()
            }
        }
        .onReceive(pub) { (output) in
            self.updateBadge()
        }
        .onChange(of: authVM.profilePic) { _ in
            Task {
                await loadProfileImage()
            }
        }
        .onChange(of: notificationManager.isPeopleTabDisplayed) { newValue in
            if newValue {
                goToTabPeople()
            }
        }
        .fullScreenCover(isPresented: $notificationManager.isPublicationDisplayed) {
            IndepCommentScreenWrapper(
                postId: notificationManager.publicationId ?? "",
                locationManager: locationManager,
                socket: socket
            )
        }
        .fullScreenCover(isPresented: $notificationManager.isChatDisplayed) {
            MessageScreenWrapper(
                chatId: notificationManager.chatId ?? "",
                username: notificationManager.username ?? "",
                otherUserUid: notificationManager.senderUserUid ?? "",
                chatPic: notificationManager.chatPic,
                isLocked: notificationManager.isLocked ?? false,
                socket: socket
            )
        }
        .fullScreenCover(isPresented: $notificationManager.isCommunityChatDisplayed) {
            CommunityMessageScreenWrapper(
                communityId: notificationManager.communityId ?? "",
                locationManager: locationManager,
                socket: socket
            )
            .environmentObject(authVM)
        }
    }
}

// MARK: - Profile Tab Label

private extension MainTabView {
    @ViewBuilder
    private func ProfileTabItemLabel() -> some View {
        ZStack {
            if let profilePicture = profileImage?.createTabItemLabelFromImage(selectedTab == 4) {
                Image(uiImage: profilePicture)
            } else {
                Label("Profile", systemImage: "person.circle.fill")
            }
        }
        .animation(.none, value: colorScheme)
    }
}

// MARK: - Private Methods

extension MainTabView {
    private func updateBadge() {
        Task {
            self.unreadChats = try await getChatBadge()
        }
    }
    
    private func listenToMessages() {
        socket.socket?.on("badge") { data, ack in
            updateBadge()
        }
    }
    
    private func getChatBadge() async throws -> Int? {
        let token = try await authVM.getFirebaseToken()
        let result = await AYServices.shared.getUnreadChatsNumber(token: token)
        
        switch result {
        case .success(let response):
            return response.quantity
        case .failure:
            print("❌ Error trying to get unread messages number.")
        }
        return nil
    }
    
    private func goToTabPeople() {
        withAnimation {
            selectedTab = 2
        }
    }
    
    private func loadProfileImage() async {
        guard let urlString = authVM.profilePic else { return }
        
        self.profileImage = await KingfisherService.shared.loadImage(from: urlString)
    }
    
}

fileprivate extension UIImage {
    func createTabItemLabelFromImage(_ isSelected: Bool) -> UIImage? {
        let imageSize = CGSize(width: 32, height: 32)
        
        return UIGraphicsImageRenderer(size: imageSize).image { context in
            let rect = CGRect(origin: .init(x: 0, y: 0), size: imageSize)
            let clipPath = UIBezierPath(ovalIn: rect)
            clipPath.addClip()
            
            self.draw(in: rect)
            if isSelected {
                context.cgContext.setStrokeColor(UIColor.label.cgColor)
                context.cgContext.setLineJoin(.round)
                context.cgContext.setLineCap(.round)
                clipPath.lineWidth = 3
                
                clipPath.stroke()
            }
        }
        .withRenderingMode(.alwaysOriginal)
    }
}
