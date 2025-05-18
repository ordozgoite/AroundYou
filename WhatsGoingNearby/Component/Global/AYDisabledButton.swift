//
//  AYDisabledButton.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 18/05/25.
//

import SwiftUI

struct AYDisabledButton: View {
    
    let title: LocalizedStringKey
    
    var body: some View {
        Button {} label: {
            HStack {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 44)
            }
        }
        .buttonStyle(.borderedProminent)
        .disabled(true)
    }
}

#Preview {
    AYDisabledButton(title: "Asked to Join")
}
