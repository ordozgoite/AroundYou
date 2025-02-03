//
//  EmojiMessageView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 27/04/24.
//

import SwiftUI

struct EmojiMessageView: View {
    
    var emoji: Character
    var isCurrentUser: Bool
    var isFirst: Bool
    
    var body: some View {
        Text(String(emoji))
            .font(.system(size: 50))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: isCurrentUser ? .trailing : .leading)
            .padding(isCurrentUser ? .leading : .trailing, 64)
            .padding(.bottom, isFirst ? 8 : 2)
            .padding(.vertical, 4)
    }
}

#Preview {
    EmojiMessageView(emoji: "🤪", isCurrentUser: true, isFirst: true)
}
