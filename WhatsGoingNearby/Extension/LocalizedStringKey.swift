//
//  LocalizedStringKey.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 05/03/24.
//

import Foundation
import SwiftUI

extension LocalizedStringKey {
    var stringKey: String {
        Mirror(reflecting: self).children.first(where: { $0.label == "key" })?.value as! String
    }
}
