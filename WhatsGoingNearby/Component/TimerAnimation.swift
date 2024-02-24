//
//  TimerAnimation.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 24/02/24.
//

import SwiftUI

struct TimerAnimation: View {
    
    @State private var progress: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray, lineWidth: 40)
                .frame(width: 200, height: 200)
                .opacity(0.5)
            
            Circle()
                .trim(from: 0.0, to: progress)
                .stroke(progress < 0.1 ? .red : .blue, lineWidth: 40)
                .rotationEffect(.degrees(-90))
                .frame(width: 200, height: 200)
        }
        .onAppear {
            animateProgress()
        }
    }
    
    private func animateProgress() {
        withAnimation(.linear(duration: 4)) {
            progress = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            withAnimation(.linear(duration: 0.7)) {
                progress = 1
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                // Chamada recursiva para iniciar novamente o processo de animação
                animateProgress()
            }
        }
    }
}

#Preview {
    TimerAnimation()
}
