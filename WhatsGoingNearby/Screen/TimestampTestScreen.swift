//
//  TimestampTestScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 14/02/24.
//

import SwiftUI

struct TimestampTestScreen: View {
    
    let timestamp = 1707970962
    
    var body: some View {
        Text(NSDate(timeIntervalSince1970: TimeInterval(Int(Date().timeIntervalSince1970) + 240)).description)
//        Text(String(Int(Date().timeIntervalSince1970)))
    }
}

#Preview {
    TimestampTestScreen()
}
