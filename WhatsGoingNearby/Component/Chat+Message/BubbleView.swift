//
//  MessageView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 27/03/24.
//

import SwiftUI

struct BubbleView: View {
    
    var message: String
    var isCurrentUser: Bool
    var isFirst: Bool
    
    var body: some View {
        Text(message)
            .foregroundStyle(isCurrentUser ? .white : .primary)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(
                isCurrentUser ? .blue : Color(uiColor: .secondarySystemBackground),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .background(alignment: isCurrentUser ? .bottomTrailing : .bottomLeading) {
                isFirst
                ?
                Image(isCurrentUser ? "outgoingTail" : "incomingTail")
                    .renderingMode(.template)
                    .foregroundStyle(isCurrentUser ? .blue : Color(uiColor: .secondarySystemBackground))
                :
                nil
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: isCurrentUser ? .trailing : .leading)
            .padding(isCurrentUser ? .leading : .trailing, 64)
            .padding(.bottom, isFirst ? 8 : 2)
    }
}

//#Preview {
//    BubbleView(message: "Já estou trabalhando na funcionalidade de mensagens, mano. Fique tranquilo 😉", isCurrentUser: true, isFirst: true)
//}
