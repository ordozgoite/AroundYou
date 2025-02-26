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
            if let sysImage = systemNameImage {
                Label(title, systemImage: sysImage)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 44, maxHeight: 44)
            } else {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 44, maxHeight: 44)
            }
        }
        .buttonStyle(.borderedProminent)
    }
}

#Preview {
    AYButton(title: "Go", systemNameImage: "map", action: {})
}
