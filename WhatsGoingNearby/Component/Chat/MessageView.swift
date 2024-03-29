//
//  MessageView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 27/03/24.
//

import SwiftUI

struct MessageView: View {
    
    var message: FormattedMessage
    
    var body: some View {
        Text(message.message)
            .foregroundStyle(message.isCurrentUser ? .white : .primary)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(
                message.isCurrentUser ? .blue : Color(uiColor: .secondarySystemBackground),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .background(alignment: message.isCurrentUser ? .bottomTrailing : .bottomLeading) {
                message.isFirst
                ?
                Image(message.isCurrentUser ? "outgoingTail" : "incomingTail")
                    .renderingMode(.template)
                    .foregroundStyle(message.isCurrentUser ? .blue : Color(uiColor: .secondarySystemBackground))
                :
                nil
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: message.isCurrentUser ? .trailing : .leading)
            .padding(message.isCurrentUser ? .leading : .trailing, 64)
            .padding(.bottom, message.isFirst ? 8 : 2)
    }
}

#Preview {
    MessageView(message: FormattedMessage(id: "1", message: "Já estou trabalhando na funcionalidade de mensagens, mano. Fique tranquilo 😉", isCurrentUser: true, isFirst: true))
}
