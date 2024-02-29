//
//  NextView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 28/02/24.
//

import Foundation
import SwiftUI

enum NextView: String, Identifiable {
    case comment
    
    var id: String {
        self.rawValue
    }
    
    @ViewBuilder
    func view() -> some View {
        switch self {
        case .comment:
            EmptyView()
        }
    }
}
