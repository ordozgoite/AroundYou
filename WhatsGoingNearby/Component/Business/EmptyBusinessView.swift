//
//  EmptyBusinessView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 15/03/25.
//

import SwiftUI

struct EmptyBusinessView: View {
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
                        Text("No business found nearby.")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
    }
}

#Preview {
    EmptyBusinessView()
}
