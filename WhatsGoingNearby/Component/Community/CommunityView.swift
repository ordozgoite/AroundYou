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
    
    var body: some View {
        VStack(alignment: .center) {
            CommunityImageView(
                imageUrl: imageUrl,
                size: imageSize
            )
            .shadow(radius: 5)
            
            VStack {
                HStack(spacing: 8) {
                    Text(name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                    if isMember {
                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundStyle(.green)
                    }
                }
                
                if isPrivate {
                    Text("Private")
                        .font(.callout)
                        .foregroundStyle(.gray)
                }
            }
        }
    }
}

#Preview {
    CommunityView(
        imageUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTdLXpuHHbuLb1QC4u4XkaqR50h4BBEqnJ1Sw&s",
        imageSize: 100,
        name: "Show Guns N' Roses",
        isMember: true,
        isPrivate: true
    )
}
