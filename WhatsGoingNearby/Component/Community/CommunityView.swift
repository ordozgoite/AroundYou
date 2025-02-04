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
            
            HStack(spacing: 8) {
                if isMember {
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(.green)
                }
                
                Text(name)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            
            if isPrivate {
                HStack {
                    Text("Private")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
//                    Image(systemName: "lock.fill")
//                        .resizable()
//                        .scaledToFit()
//                        .frame(width: 16, height: 16, alignment: .center)
//                        .foregroundStyle(.gray)
                }
            }
        }
    }
}

#Preview {
    CommunityView(imageUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTdLXpuHHbuLb1QC4u4XkaqR50h4BBEqnJ1Sw&s", imageSize: 100, name: "Show Guns N' Roses", isMember: true, isPrivate: true)
}
