//
//  BlurView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 31/01/25.
//

import Foundation
import SwiftUI

struct BlurView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
