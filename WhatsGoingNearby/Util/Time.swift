//
//  Time.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 16/02/24.
//

import Foundation

public func getCurrentDateTimestamp() -> Int {
    return Int(Date().timeIntervalSince1970)
}
