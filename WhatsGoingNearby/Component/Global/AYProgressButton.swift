//
//  AYProgressButton.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import SwiftUI

struct AYProgressButton: View {
    
    let title: String
    
    var body: some View {
        Button {} label: {
            HStack {
                ProgressView()
                
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 32)
            }
        }
        .buttonStyle(.borderedProminent)
        .disabled(true)
    }
}

#Preview {
    AYProgressButton(title: "Enviando...")
}
