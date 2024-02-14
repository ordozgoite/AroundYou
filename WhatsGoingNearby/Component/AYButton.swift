//
//  AYButton.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import SwiftUI

struct AYButton: View {
    
    let title: String
    let action: () -> ()
    
    var body: some View {
        Button {
            action()
        } label: {
            Text(title)
                .fontWeight(.bold)
                .frame(width: 256, height: 32)
        }
        .buttonStyle(.borderedProminent)
    }
}

#Preview {
    AYButton(title: "Entrar", action: {})
}
