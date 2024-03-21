//
//  Int.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 15/02/24.
//

import Foundation

extension Int {
    var timeIntervalSince1970InSeconds: Int {
        return self / 1000
    }
    
    func convertTimestampToString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yy"
        let date = Date(timeIntervalSince1970: Double(timeIntervalSince1970InSeconds))
        let dateString = dateFormatter.string(from: date)
        return dateString
    }
    
    func convertTimestampToDate() -> Date {
        return Date(timeIntervalSince1970: Double(timeIntervalSince1970InSeconds))
    }
}
