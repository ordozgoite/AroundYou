//
//  LottieView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 16/02/24.
//

import SwiftUI
import Lottie

struct LottieView: UIViewRepresentable {
    
    let name: String
    let loopMode: LottieLoopMode
    
    func makeUIView(context: Context) -> Lottie.LottieAnimationView {
        let animationView = LottieAnimationView(name: name)
        animationView.loopMode = loopMode
        animationView.play()
        return animationView
    }
    
    func updateUIView(_ uiView: Lottie.LottieAnimationView, context: Context) {
        
    }
}
