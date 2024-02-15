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
    
    @State private var progress: CGFloat = 0.0
    
    var body: some View {
        Circle()
            .trim(from: 0.0, to: progress)
            .stroke(Color.blue, lineWidth: 8)
            .rotationEffect(.degrees(-90))
            .frame(width: 20, height: 20)
            .onAppear {
                startTimer()
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
    
    private func getCurrentDateTimestamp() -> Int {
        return Int(Date().timeIntervalSince1970)
    }
}

#Preview {
    CircleTimerView(postDate: 1707993786, expirationDate: 1707994786)
}
