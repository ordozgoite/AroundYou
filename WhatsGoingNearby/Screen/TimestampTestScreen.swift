//
//  TimestampTestScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 14/02/24.
//

import SwiftUI

struct TimestampTestScreen: View {
    var body: some View {
        Text(String(Int(Date().timeIntervalSince1970)))
    }
}

#Preview {
    TimestampTestScreen()
}
