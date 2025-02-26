//
//  MainTabView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import SwiftUI

struct MainTabView: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var socket = SocketService()
    @StateObject public var notificationManager = NotificationManager()
    @StateObject private var locationManager = LocationManager()
    @Environment(\.colorScheme) var colorScheme
    
    @State private var isPeopleTabDisplayed: Bool = false
    @State private var selectedTab: Int = 0
    @State private var profileImage: UIImage?
    
    var body: some View {
        TabView(selection: $selectedTab) {
            FeedScreen(locationManager: locationManager, socket: socket)
                .tabItem {
                    Label("Posts", systemImage: "quote.bubble.fill")
                }
                .environmentObject(authVM)
                .tag(0)
            
            CommunityListScreen(locationManager: locationManager, socket: socket)
                .tabItem {
                    Label("Communities", systemImage: "person.3.fill")
                }
                .environmentObject(authVM)
                .tag(1)
            
            DiscoverScreen(locationManager: locationManager, socket: socket)
                .tabItem {
                    Label("People", systemImage: "heart.fill")
                }
                .environmentObject(authVM)
                .tag(2)
            
            BusinessScreen()
                .tabItem {
                    Label("Business", systemImage: "storefront.fill")
                }
                .environmentObject(authVM)
                .tag(3)
            
            AccountScreen(socket: socket)
                .tabItem {
                    ProfileTabItemLabel()
                }
                .environmentObject(authVM)
                .tag(4)
        }
        .onAppear {
            loadProfileImage()
        }
        .onChange(of: authVM.profilePic) { _ in
            loadProfileImage()
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
                socket: socket)
        }
        .fullScreenCover(isPresented: $notificationManager.isChatDisplayed) {
            MessageScreenWrapper(
                chatId: notificationManager.chatId ?? "",
                username: notificationManager.username ?? "",
                otherUserUid: notificationManager.senderUserUid ?? "",
                chatPic: notificationManager.chatPic,
                socket: socket)
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
    private func goToTabPeople() {
        withAnimation {
            selectedTab = 2
        }
    }
    
    private func loadProfileImage() {
        guard let urlString = authVM.profilePic, let url = URL(string: urlString) else { return }
        
        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: url), let uiImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.profileImage = uiImage
                }
            }
        }
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
