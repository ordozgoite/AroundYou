//
//  EmptyDiscoverView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 22/01/25.
//

import SwiftUI

struct EmptyDiscoverView: View {
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
                        Text("No matches found nearby.")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("You can enable Discover Notifications to stay updated when someone matching your interests is nearby.")
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
    EmptyDiscoverView()
}
