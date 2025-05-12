//
//  FloatingHeartsView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 26/10/24.
//

import SwiftUI

struct FloatingHeartsView: View {
    
    @State private var hearts = [Heart]()
    var color: Color
    
    var body: some View {
        ZStack {
            ForEach(hearts) { heart in
                Image(systemName: "heart.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(color)
                    .frame(width: heart.size, height: heart.size)
                    .position(heart.position)
                    .opacity(heart.opacity)
                    .animation(
                        Animation.linear(duration: heart.duration)
                            .repeatForever(autoreverses: false),
                        value: heart.position
                    )
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                addHeart()
            }
        }
    }
    
    private func addHeart() {
        let randomX = CGFloat.random(in: 0...UIScreen.main.bounds.width - 20)
        let heart = Heart(
            id: UUID(),
            size: CGFloat.random(in: 20...40),
            position: CGPoint(x: randomX, y: UIScreen.main.bounds.height - 200)
        )
        hearts.append(heart)
        
        withAnimation {
            hearts = hearts.map { heart in
                var updatedHeart = heart
                updatedHeart.position.y = -50
                return updatedHeart
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            hearts.removeAll { $0.id == heart.id }
        }
    }
}

struct Heart: Identifiable {
    let id: UUID
    let size: CGFloat
    var position: CGPoint
    var opacity: Double = 1
    var duration: Double = Double.random(in: 3.5...5)
}


#Preview {
    FloatingHeartsView(color: .purple)
}
