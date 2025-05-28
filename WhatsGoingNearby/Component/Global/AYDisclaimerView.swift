//
//  AYDisclaimerView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 22/05/25.
//

import SwiftUI

struct AYDisclaimerView: View {
    let text: LocalizedStringKey
    
    var body: some View {
        Label(
            text,
            systemImage: "info.circle"
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(.gray)
        .italic()
        .font(.footnote)
    }
}

#Preview {
    AYDisclaimerView(text: "Posts are shown only to those around you.")
}
