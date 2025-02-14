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
            ZStack {
                CircleTimerView(postDate: creationDate, expirationDate: expirationDate, size: imageSize + 8)
                
                CommunityImageView(
                    imageUrl: imageUrl,
                    size: imageSize
                )
                .shadow(radius: 5)
            }
            
            VStack {
                HStack(spacing: 8) {
                    Text(name)
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
//                    if isMember {
//                        Image(systemName: "checkmark.circle.fill")
//                            .resizable()
//                            .frame(width: 24, height: 24)
//                            .foregroundStyle(.green)
//                    }
                }
                
                if isPrivate {
                    Text("Private")
                        .padding(2)
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.gray, lineWidth: 2)
                        )
                        .offset(y: -2)
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
        isPrivate: true,
        creationDate: 1739383886394,
        expirationDate: 1739387486394
    )
}
