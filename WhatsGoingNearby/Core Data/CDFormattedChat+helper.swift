////
////  CDFormattedChat+helper.swift
////  WhatsGoingNearby
////
////  Created by Victor Ordozgoite on 14/05/24.
////
//
//import Foundation
//import CoreData
//
//extension CDFormattedChat {
//    convenience init(fromChat chat: FormattedChat, context: NSManagedObjectContext) {
//        self.init(context: context)
//        self.id = chat.id
//        self.chatPic = chat.chatPic
//        self.chatName = chat.chatName
//        self.hasUnreadMessages = chat.hasUnreadMessages
//        self.isMuted = chat.isMuted
//        self.lastMessage = chat.lastMessage
//        self.lastMessageAt = chat.lastMessageAt?.convertTimestampToDate()
//        self.otherUserUid = chat.otherUserUid
//        self.isLocked = chat.isLocked
//    }
//    
//    static func delete(chat: CDFormattedChat) {
//        guard let context = chat.managedObjectContext else { return }
//        
//        context.delete(chat)
//    }
//    
//    static func fetch(_ predicate: NSPredicate = .all) -> NSFetchRequest<CDFormattedChat> {
//        let request = CDFormattedChat.fetchRequest()
//        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDFormattedChat.lastMessageAt, ascending: false)]
//        request.predicate = predicate
//        
//        return request
//    }
//    
//    func convertToFormattedMessage() -> FormattedChat {
//        return FormattedChat(
//            id: self.id ?? UUID().uuidString,
//            chatName: self.chatName ?? "Unknown",
//            otherUserUid: self.otherUserUid ?? "",
//            chatPic: self.chatPic,
//            lastMessageAt: self.lastMessageAt == nil ? nil : Int(self.lastMessageAt!.timeIntervalSince1970),
//            hasUnreadMessages: self.hasUnreadMessages,
//            lastMessage: self.lastMessage,
//            isMuted: self.isMuted,
//            isLocked: self.isLocked
//        )
//    }
//}
