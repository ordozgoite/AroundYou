//
//  CircleTimerView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 15/02/24.
//

import SwiftUI

struct CircleTimerView: View {
    
    let postDate: Int
    let expirationDate: Int
    let size: CGFloat
    
    @State private var progress: CGFloat = 0.0
    
    init(postDate: Int, expirationDate: Int, size: CGFloat = 20) {
        self.postDate = postDate
        self.expirationDate = expirationDate
        self.size = size
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray, lineWidth: 4)
                .frame(width: size, height: size)
                .opacity(0.5)
            
            Circle()
                .trim(from: 0.0, to: progress)
                .stroke(progress < 0.1 ? .red : .blue, lineWidth: 4)
                .rotationEffect(.degrees(-90))
                .frame(width: size, height: size)
                .onAppear {
                    startTimer()
                }
        }
    }
    
    private func startTimer() {
        let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            updateProgress()
        }
        timer.fire()
    }
    
    private func updateProgress() {
        let timeLeft = expirationDate - getCurrentDateTimestamp()
        let completeTime = expirationDate - postDate
        let newProgress = CGFloat(timeLeft) / CGFloat(completeTime)
        withAnimation {
            self.progress = newProgress
        }
    }
}

#Preview {
    CircleTimerView(postDate: 1707993786, expirationDate: 1707994786)
}
