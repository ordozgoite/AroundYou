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
    
    var body: some View {
        VStack {
            HStack {
                ProfilePicView(profilePic: notification.imageUrl, size: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(notification.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    if let subtitle = notification.subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                
                if notification.route != nil {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .imageScale(.small)
                        .padding(.leading, 4)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .shadow(radius: 4)
            .onTapGesture {
                onTap()
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    NotificationBannerView(notification: AppBannerNotification(title: "amanda", subtitle: "Ooi, meu amor!", imageUrl: nil, route: .createBusiness), onTap: {})
}
