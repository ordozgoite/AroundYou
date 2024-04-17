//
//  Color.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 16/04/24.
//

import Foundation
import SwiftUI

extension ShapeStyle where Self == Color {
    static var random: Color {
        Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        )
    }
}
