//
//  EmptyCommunityView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 12/02/25.
//

import SwiftUI

struct EmptyCommunityView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LottieView(name: "radar", loopMode: .loop)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .opacity(0.25)
                
                VStack(spacing: 16) {
                    Image(systemName: "location.magnifyingglass")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50)
                        .foregroundStyle(.gray)
                    
                    VStack {
                        Text("No communities found nearby.")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("Be the first to create a community in your region...")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                        .fontWeight(.regular)
                        .multilineTextAlignment(.center)
                        .frame(width: screenWidth - 32)
                    }
                }
            }
        }
    }
}

#Preview {
    EmptyCommunityView()
}
