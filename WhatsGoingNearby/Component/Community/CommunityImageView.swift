//
//  CommunityImageView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 03/02/25.
//

import SwiftUI

struct CommunityImageView: View {
    
    init(imageUrl: String?, size: CGFloat = 50) {
        self.imageUrl = imageUrl
        self.size = size
    }
    
    let imageUrl: String?
    let size: CGFloat
    
    var body: some View {
        if let url = imageUrl {
            URLNotTapableImageView(imageURL: url)
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            CommunityIconCircleFill(size: size)
        }
    }
}

#Preview {
    CommunityImageView(imageUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTdLXpuHHbuLb1QC4u4XkaqR50h4BBEqnJ1Sw&s")
    
    CommunityImageView(imageUrl: nil)
}
