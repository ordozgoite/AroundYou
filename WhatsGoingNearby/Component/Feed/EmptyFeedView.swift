//
//  EmptyFeedView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 16/02/24.
//

import SwiftUI

struct EmptyFeedView: View {
    var body: some View {
        ZStack {
            LottieView(name: "radar", loopMode: .loop)
                .opacity(0.25)
            
            VStack(spacing: 16) {
                Image(systemName: "location.magnifyingglass")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50)
                    .foregroundStyle(.gray)
                
                VStack {
                    Text("No posts found.")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    Text("No worries, we are always looking around you...")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
}

#Preview {
    EmptyFeedView()
}
