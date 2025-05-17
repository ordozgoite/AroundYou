//
//  DisclaimerTestView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 16/05/25.
//

import SwiftUI

struct DisclaimerTestView: View {
    var body: some View {
        Label(
            "Only people nearby this post can interact with it, including the owner.",
            systemImage: "info.circle"
        )
        .foregroundStyle(.gray)
        .italic()
        .padding()
    }
}

#Preview {
    DisclaimerTestView()
}
