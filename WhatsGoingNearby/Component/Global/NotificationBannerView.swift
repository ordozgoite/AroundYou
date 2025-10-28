//
//  NotificationBannerView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 29/05/25.
//

import SwiftUI

/*
 Essa View será usada, a priori, apenas para exibir mensagens do chat.
 Pode ser usada também, mais pra frente, pra exibir qualquer tipo de notificação (curtidas, comentátios etc.)
 */

struct AppBannerNotification: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let imageUrl: String?
    let route: AppRoute?
}

struct NotificationBannerView: View {
    let notification: AppBannerNotification
    let onTap: () -> Void
    let onDismiss: () -> Void
    
    @State private var dragOffset: CGSize = .zero
    
    var body: some View {
        VStack {
            if #available(iOS 26.0, *) {
                HStack {
                    BannerContent()
                }
                .padding()
                .cornerRadius(12)
                .glassEffect()
                .contentShape(Rectangle())
                .onTapGesture { onTap() }
            } else {
                HStack {
                    BannerContent()
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .shadow(radius: 4)
                .onTapGesture { onTap() }
            }
        }
        .padding(.horizontal)
        .offset(y: dragOffset.height)
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                }
                .onEnded { value in
                    if value.translation.height < -50 {
                        onDismiss()
                    }
                    dragOffset = .zero
                }
        )
        .animation(.easeInOut, value: dragOffset)
    }
    
    // MARK: - Content
    
    @ViewBuilder
    private func BannerContent() -> some View {
        ProfilePicView(profilePic: notification.imageUrl, size: 32)
        
        VStack(alignment: .leading, spacing: 2) {
            TitleView()
            BodyView()
        }
        
        Spacer()
        Chevron()
    }
    
    // MARK: - Title
    
    @ViewBuilder
    private func TitleView() -> some View {
        Text(notification.title)
            .font(.headline)
            .foregroundColor(.primary)
    }
    
    // MARK: - Body
    
    @ViewBuilder
    private func BodyView() -> some View {
        if let subtitle = notification.subtitle {
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Chevron
    
    @ViewBuilder
    private func Chevron() -> some View {
        if notification.route != nil {
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .imageScale(.small)
                .padding(.leading, 4)
        }
    }
}

#Preview {
    NotificationBannerView(notification: AppBannerNotification(title: "amanda", subtitle: "Ooi, meu amor!", imageUrl: nil, route: .createBusiness), onTap: {}, onDismiss: {})
}
