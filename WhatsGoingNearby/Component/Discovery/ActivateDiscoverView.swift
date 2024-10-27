//
//  ActivateDiscoverView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 25/10/24.
//

import SwiftUI

struct ActivateDiscoverView: View {
    var body: some View {
        ZStack {
            FloatingHeartsView(color: .purple)
            
            VStack {
                Spacer()
                
                VStack(spacing: 32) {
                    ImageView()
                    
                    DisclaimerView()
                }
                
                Spacer()
                
                DiscoverButton()
                
            }
        }
        .padding()
    }
    
    //MARK: - ImageView
    
    @ViewBuilder
    private func ImageView() -> some View {
        Image(systemName: "flame")
            .resizable()
            .scaledToFit()
            .frame(width: 128, height: 128)
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.purple, Color.blue],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }
    
    //MARK: - Disclaimer
    
    @ViewBuilder
    private func DisclaimerView() -> some View {
        Text("Connect with those nearby. A match could spark a new friendship, an unexpected adventure, or maybe even something unforgettable.")
            .multilineTextAlignment(.center)
            .font(.callout)
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.purple, Color.blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
    }
    
    //MARK: - DiscoverButton
    
    @ViewBuilder
    private func DiscoverButton() -> some View {
        Button {
            // activate discover
        } label: {
            Text("Find Connections")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 64, maxHeight: 64)
                .background(
                    LinearGradient(
                        colors: [Color.purple, Color.blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        }
    }
}

#Preview {
    ActivateDiscoverView()
}
