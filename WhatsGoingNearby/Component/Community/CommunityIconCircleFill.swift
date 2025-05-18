//
//  CommunityCircleFill.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 18/05/25.
//

import SwiftUI

struct CommunityIconCircleFill: View {
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .fill(.gray)
                .frame(width: size, height: size)

            Image(systemName: Constants.communityIconImageName)
                .resizable()
                .foregroundColor(.white)
                .scaledToFit()
                .padding(size / 5)
                .frame(width: size, height: size)
        }
    }
}

#Preview {
    CommunityIconCircleFill(size: 160)
}
