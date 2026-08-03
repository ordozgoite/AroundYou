//
//  AYButton.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import SwiftUI

struct AYButton: View {
    
    let title: LocalizedStringKey
    let systemNameImage: String?
    let action: () -> ()
    
    init(title: LocalizedStringKey, systemNameImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemNameImage = systemNameImage
        self.action = action
    }
    
    var body: some View {
        Button {
            action()
        } label: {
            content
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.accentColor)
                .clipShape(Capsule())
        }
        .buttonStyle(.borderedProminent)
    }
    
    // MARK: - Content
    
    @ViewBuilder
    private var content: some View {
        if let sysImage = systemNameImage {
            Label(title, systemImage: sysImage)
        } else {
            Text(title)
        }
    }
}

#Preview {
    AYButton(title: "Go", systemNameImage: "map", action: {})
}
