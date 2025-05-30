//
//  ChatMessageFromNotificationView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 30/05/25.
//

import SwiftUI

struct ChatMessageFromNotificationView: View {
    let chat: FormattedChat
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            MessageScreen(
                chatId: chat.id,
                username: chat.chatName,
                otherUserUid: chat.otherUserUid,
                chatPic: chat.chatPic,
                isLocked: chat.isLocked
            )
            .navigationBarItems(leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }, label: {
                Image(systemName: "xmark")
            }))
        }
    }
}

//#Preview {
//    ChatMessageFromNotificationView()
//}
