//
//  MainTabView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import SwiftUI
import Kingfisher
import UserNotifications

struct MainTabView: View {

    private static let listenerOwner = "main-tab"

    @EnvironmentObject var authVM: AuthenticationViewModel
    @EnvironmentObject var socket: SocketService
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var router: AppRouter
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.scenePhase) private var scenePhase

    let pub = NotificationCenter.default
        .publisher(for: .updateBadge)
    @State private var launchAnimationObserver = NotificationCenter.default
        .publisher(for: .launchAnimationFinished)

    @State private var profileImage: UIImage?
    @State private var badgeTimer: Timer?
    @State private var unreadChats: Int?

    var body: some View {
        // A aba selecionada e as pilhas de cada aba moram no router: é o que permite que uma
        // notificação ajuste a navegação sem precisar de uma tela apresentada por cima.
        TabView(selection: $router.selectedTab) {
            HomeScreen()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .environmentObject(router.homeNav)
                .tag(AppRouter.Tab.home)

            ChatListScreen()
                .tabItem {
                    Label("Chats", systemImage: "bubble.left")
                }
                .environmentObject(router.chatNav)
                .badge(unreadChats ?? 0)
                .tag(AppRouter.Tab.chats)

            AccountScreen()
                .tabItem {
                    ProfileTabItemLabel()
                }
                .environmentObject(router.accountNav)
                .tag(AppRouter.Tab.account)
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
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                updateBadge()
            }
        }
        .fullScreenCover(isPresented: $notificationManager.isPublicationDisplayed) {
            IndepCommentScreenWrapper(
                postId: notificationManager.publicationId ?? ""
            )
        }
        .onChange(of: notificationManager.isCommunityChatDisplayed) { newValue in
            if newValue {
                router.homeNav.goToRoot()
            }
        }
        .fullScreenCover(isPresented: $notificationManager.isCommunityChatDisplayed) {
            CommunityMessageScreenWrapper(
                communityId: notificationManager.communityId ?? ""
            )
        }
        .overlay(alignment: .top) {
            Group {
                if let notification = socket.currentNotification,
                   shouldShowBanner(for: notification) {
                    NotificationBannerView(
                        notification: notification,
                        onTap: {
                            if let route = notification.route {
                                router.handleNotificationRoute(route)
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
            // Quem já está na conversa não precisa ser avisado dela.
            return router.currentChatId != chat.id
        default:
            return true
        }
    }
}

// MARK: - Profile Tab Label

private extension MainTabView {
    @ViewBuilder
    private func ProfileTabItemLabel() -> some View {
        ZStack {
            // O contorno de seleção nunca chegou a ser desenhado (a comparação era com uma
            // aba que não existe), e continua desligado para não mudar a aparência da tab bar.
            if let profilePicture = profileImage?.createTabItemLabelFromImage(false) {
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
            guard let unreadChats = try await getChatBadge() else { return }
            self.unreadChats = unreadChats
            UNUserNotificationCenter.current().setBadgeCount(unreadChats) { error in
                if let error {
                    print("❌ Unable to update app icon badge: \(error.localizedDescription)")
                }
            }
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
