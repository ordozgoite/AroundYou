//
//  String.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 14/02/24.
//

import Foundation

extension String {
    func convertToTimestamp() -> Int? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        if let date = dateFormatter.date(from: self) {
            return Int(date.timeIntervalSince1970)
        } else {
            return nil
        }
    }
    
    func nonEmptyOrNil() -> String? {
        return self.isEmpty ? nil : self
    }
    
    var isSingleEmoji: Bool { count == 1 && containsEmoji }
    
    var containsEmoji: Bool { contains { $0.isEmoji } }
    
    func normalizePhoneNumber() -> String {
        return self.filter { $0.isNumber }
    }
}
