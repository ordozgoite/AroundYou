//
//  JoinCommunityView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 16/02/25.
//

import SwiftUI

struct JoinCommunityView: View {
    
    @Binding var isViewDisplayed: Bool
    var community: FormattedCommunity
    
    var body: some View {
        VStack(spacing: 32) {
            CloseButton()
            
            VStack {
                CommunityImage()
                
                CommunityName()
            }
            
            CommunityDescription()
            
            JoinButton()
        }
        .padding(20)
        .frame(maxWidth: 320)
        .background(.thinMaterial)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Close Button
    
    @ViewBuilder
    private func CloseButton() -> some View {
        HStack {
            Spacer()
            
            Button {
                self.isViewDisplayed = false
            } label: {
                Image(systemName: "xmark")
            }
        }
    }
    
    // MARK: - Image
    
    @ViewBuilder
    private func CommunityImage() -> some View {
        ZStack(alignment: .center) {
            CircleTimerView(postDate: community.createdAt.timeIntervalSince1970InSeconds, expirationDate: community.expirationDate.timeIntervalSince1970InSeconds, size: 136)
            
            CommunityImageView(imageUrl: community.imageUrl, size: 128)
                .shadow(radius: 5)
        }
    }
    
    // MARK: - Name
    
    @ViewBuilder
    private func CommunityName() -> some View {
        Text(community.name)
            .font(.title)
            .bold()
    }
    
    // MARK: - Description
    
    @ViewBuilder
    private func CommunityDescription() -> some View {
        if let description = community.description {
            Text(description)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Join Button
    
    @ViewBuilder
    private func JoinButton() -> some View {
        AYButton(title: community.isPrivate ? "Ask To Join" : "Join") {
            // Join Community
        }
    }
}

#Preview {
    JoinCommunityView(isViewDisplayed: .constant(true), community: FormattedCommunity(id: UUID().uuidString, name: "Condomínio Anaíra", imageUrl: nil, description: "Comunidade apenas para moradores do Anaíra", createdAt: 1, expirationDate: 1, isMember: false, isPrivate: true))
}
