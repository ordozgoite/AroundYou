//
//  CommunityView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 03/02/25.
//

import SwiftUI

struct CommunityView: View {
    
    let imageUrl: String?
    let imageSize: CGFloat
    let name: String
    let isMember: Bool
    let isPrivate: Bool
    let creationDate: Int
    let expirationDate: Int
    
    var body: some View {
        VStack(alignment: .center) {
            ZStack(alignment: .center) {
                CircleTimerView(postDate: creationDate, expirationDate: expirationDate, size: imageSize + 8)
                
                CommunityImageView(
                    imageUrl: imageUrl,
                    size: imageSize
                )
                .shadow(radius: 5)
            }
            
            Text(name)
                .font(.callout)
                .fontWeight(isMember ? .bold : .medium)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    CommunityView(
        imageUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTdLXpuHHbuLb1QC4u4XkaqR50h4BBEqnJ1Sw&s",
        imageSize: 100,
        name: "Show Guns N' Roses",
        isMember: true,
        isPrivate: true,
        creationDate: 1739748535269,
        expirationDate: 1739762935269
    )
}
