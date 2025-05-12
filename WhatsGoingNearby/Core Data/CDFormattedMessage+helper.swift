////
////  CDFormattedMessage+helper.swift
////  WhatsGoingNearby
////
////  Created by Victor Ordozgoite on 14/05/24.
////
//
//import Foundation
//import CoreData
//import SwiftUI
//
//extension CDFormattedMessage {
//    convenience init(fromMessage message: FormattedMessage, context: NSManagedObjectContext) {
//        self.init(context: context)
//        self.id = message.id
//        self.chatId = message.id
//        self.image = message.image?.pngData()
//        self.imageUrl = message.imageUrl
//        self.isCurrentUser = message.isCurrentUser
//        self.isFirst = message.isFirst
//        self.message = message.message
//        self.repliedMessageId = message.repliedMessageId
//        self.repliedMessageText = message.repliedMessageText
//        self.status = message.status.rawValue
//        self.timeDivider = message.timeDivider?.convertTimestampToDate()
//    }
//    
//    static func delete(chat: CDFormattedChat) {
//        guard let context = chat.managedObjectContext else { return }
//        
//        context.delete(chat)
//    }
//    
//    static func fetch(_ predicate: NSPredicate = .all) -> NSFetchRequest<CDFormattedMessage> {
//        let request = CDFormattedMessage.fetchRequest()
//        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDFormattedMessage.createdAt, ascending: false)]
//        request.predicate = predicate
//        
//        return request
//    }
//    
//    func convertToFormattedMessage() -> FormattedMessage {
//        return FormattedMessage(
//            id: self.id ?? "",
//            chatId: self.chatId ?? "",
//            message: self.message,
//            imageUrl: self.imageUrl,
//            isCurrentUser: self.isCurrentUser,
//            isFirst: self.isFirst,
//            repliedMessageText: self.repliedMessageText,
//            repliedMessageId: self.repliedMessageId,
//            timeDivider: self.timeDivider == nil ? nil : Int(self.timeDivider!.timeIntervalSince1970),
//            image: self.image == nil ? nil : UIImage(data: self.image!),
//            status: getStatus(fromString: self.status ?? "sent"), 
//            createdAt: Int(self.createdAt)
//        )
//    }
//    
//    private func getStatus(fromString statusString: String) -> MessageStatus {
//        switch statusString {
//        case "sent":
//            return .sent
//        case "sending":
//            return .sending
//        case "failed":
//            return .failed
//        default:
//            return .sent
//        }
//    }
//}
