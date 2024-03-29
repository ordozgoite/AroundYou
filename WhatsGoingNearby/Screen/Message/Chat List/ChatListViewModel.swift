//
//  ChatListViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 28/03/24.
//

import Foundation
import SwiftUI

@MainActor
class ChatListViewModel: ObservableObject {
    
    @Published var chats: [FormattedChat] = []
    @Published var isLoading: Bool = false
    @Published var overlayError: (Bool, LocalizedStringKey) = (false, "")
    
    func getChats(token: String) async {
        isLoading = true
        let result = await AYServices.shared.getChatsByUser(token: token)
        isLoading = false
        
        switch result {
        case .success(let chats):
            self.chats = chats
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
    }
}
