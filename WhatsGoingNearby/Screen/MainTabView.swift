//
//  MainTabView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import SwiftUI
import Kingfisher

struct MainTabView: View {

    private static let listenerOwner = "main-tab"

    @EnvironmentObject var authVM: AuthenticationViewModel
    @EnvironmentObject var socket: SocketService
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var locationManager: LocationManager
    @Environment(\.colorScheme) var colorScheme
    
    let pub = NotificationCenter.default
        .publisher(for: .updateBadge)
    @State private var launchAnimationObserver = NotificationCenter.default
        .publisher(for: .launchAnimationFinished)
    
    @State private var selectedTab: Int = 0
    @State private var profileImage: UIImage?
    @State private var badgeTimer: Timer?
    @State private var unreadChats: Int?
    @State private var presentedChat: FormattedChat? = nil
    
    @StateObject private var homeNav = NavigationCoordinator()
    @StateObject private var chatNav = NavigationCoordinator()
    @StateObject private var accountNav = NavigationCoordinator()
    @StateObject private var sheetNav = NavigationCoordinator()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeScreen()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .environmentObject(homeNav)
                .tag(0)
            
            ChatListScreen()
                .tabItem {
                    Label("Chats", systemImage: "bubble.left")
                }
                .environmentObject(chatNav)
                .badge(unreadChats ?? 0)
                .tag(1)
            
            AccountScreen()
                .tabItem {
                    ProfileTabItemLabel()
                }
                .environmentObject(accountNav)
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
        .onReceive(launchAnimationObserver) { _ in
            processPendingNotifications()
        }
        .onChange(of: authVM.profilePic) { _ in
            Task {
                await loadProfileImage()
            }
        }
        .fullScreenCover(isPresented: $notificationManager.isPublicationDisplayed) {
            IndepCommentScreenWrapper(
                postId: notificationManager.publicationId ?? ""
            )
        }
        .onChange(of: socket.pendingFullScreenRoute) { newValue in
            if case let .messages(chat) = newValue {
                print("✉️ Chat: \(chat)")
                presentedChat = chat
            }
        }
        .fullScreenCover(isPresented: $notificationManager.isChatDisplayed) {
            MessageScreenWrapper(
                chatId: notificationManager.chatId ?? "",
                username: notificationManager.username ?? "",
                otherUserUid: notificationManager.senderUserUid ?? "",
                chatPic: notificationManager.chatPic,
                isLocked: notificationManager.isLocked ?? false
            )
            .environmentObject(sheetNav)
        }
        .onChange(of: notificationManager.isCommunityChatDisplayed) { newValue in
            if newValue {
                homeNav.goToRoot()
            }
        }
        .fullScreenCover(isPresented: $notificationManager.isCommunityChatDisplayed) {
            CommunityMessageScreenWrapper(
                communityId: notificationManager.communityId ?? ""
            )
        }
        .fullScreenCover(item: $presentedChat) { chat in
            ChatMessageFromNotificationView(chat: chat)
                .environmentObject(sheetNav)
        }
        .overlay(alignment: .top) {
            Group {
                if let notification = socket.currentNotification,
                   shouldShowBanner(for: notification) {
                    NotificationBannerView(
                        notification: notification,
                        onTap: {
                            if let route = notification.route {
                                socket.pendingFullScreenRoute = route
                            }
                            socket.dismissCurrentNotification()
                        },
                        onDismiss: {
                            socket.dismissCurrentNotification()
                        }
                    )
                    .padding(.top, 44)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: socket.currentNotification)
        }
    }
}

// MARK: - Notification Banner

extension MainTabView {
    private func shouldShowBanner(for notification: AppBannerNotification) -> Bool {
        guard let route = notification.route else { return true }

        switch route {
        case .messages(let chat):
            return !isCurrentlyInChat(chatId: chat.id)
        default:
            return true
        }
    }
    
    private func isCurrentlyInChat(chatId: String) -> Bool {
        guard selectedTab == 1 else { return false }
        guard let last = chatNav.path.last else { return false }
        if case let .messages(chat) = last {
            return chat.id == chatId
        }
        return false
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
    private func processPendingNotifications() {
        notificationManager.isReady = true
        notificationManager.pendingPayload?()
        notificationManager.pendingPayload = nil
    }
    
    private func updateBadge() {
        Task {
            self.unreadChats = try await getChatBadge()
        }
    }
    
    private func listenToMessages() {
        socket.addListener(for: "badge", owner: Self.listenerOwner) { data, ack in
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
