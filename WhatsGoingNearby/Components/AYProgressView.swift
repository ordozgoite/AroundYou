//
//  AYProgressView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import SwiftUI

struct AYProgressView: View {
    
    @State private var opacity: Double = 1.0
    
    var body: some View {
        Image(systemName: "location.magnifyingglass")
            .resizable()
            .scaledToFit()
            .frame(width: 50)
            .foregroundStyle(.gray)
            .opacity(opacity)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 1).repeatForever()) {
                    opacity = 0.2
                }
            }
    }
}

#Preview {
    AYProgressView()
}
