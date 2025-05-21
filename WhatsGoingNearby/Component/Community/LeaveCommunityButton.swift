//
//  LeaveCommunityButton.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 20/05/25.
//

import SwiftUI

struct LeaveCommunityButton: View {
    var body: some View {
        Image(systemName: "arrow.right.circle")
            .resizable()
            .scaledToFit()
            .frame(width: 20, height: 20)
            .foregroundStyle(.white)
            .background(Circle().fill(.gray))
            .contentShape(Circle())
    }
}


#Preview {
    LeaveCommunityButton()
}
