//
//  LockedChatView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 25/01/25.
//

import SwiftUI

struct LockedChatView: View {
    
    let username: String
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 16) {
            Image(systemName: "ellipsis.bubble")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48, alignment: .center)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.purple, Color.blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(alignment: .leading) {
                Text("Invite \(username) to chat")
                    .fontWeight(.bold)
                    .font(.callout)
                
                Text("You can send only one message with this invite. The chat will unlock once they respond.")
                    .foregroundStyle(.gray)
                    .font(.callout)
            }
        }
        .padding()
    }
}

#Preview {
    LockedChatView(username: "amanda")
}
