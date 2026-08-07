//
//  View.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 15/02/24.
//

import Foundation
import SwiftUI

/// Mesma vibração do helper de `View`, disponível fora de uma `View`
/// (view models e serviços, que também precisam avisar o usuário).
@MainActor
func triggerHapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
    let feedbackGenerator = UIImpactFeedbackGenerator(style: style)
    feedbackGenerator.prepare()
    feedbackGenerator.impactOccurred()
}

extension View {
    func hapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        triggerHapticFeedback(style: style)
    }
}
