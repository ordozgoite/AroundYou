//
//  CommunityView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 03/02/25.
//

import SwiftUI

struct CommunityView: View {
    var body: some View {
        VStack {
            CommunityImageView(
                imageUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTdLXpuHHbuLb1QC4u4XkaqR50h4BBEqnJ1Sw&s",
                size: 100
            )
            
            Text("Show Guns N' Roses")
                .font(.title3)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    CommunityView()
}
