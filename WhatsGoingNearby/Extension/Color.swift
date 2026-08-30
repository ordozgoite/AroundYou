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

extension Color {
    /// Roxo do topo do logo do app.
    static let ayBrandPurple = Color(red: 133 / 255, green: 51 / 255, blue: 159 / 255)
    /// Azul do rodapé do logo do app.
    static let ayBrandBlue = Color(red: 56 / 255, green: 185 / 255, blue: 226 / 255)
}

extension LinearGradient {
    /// Degradê da marca, com as mesmas cores do logo do app.
    static let ayBrand = LinearGradient(
        colors: [.ayBrandPurple, .ayBrandBlue],
        startPoint: .leading,
        endPoint: .trailing
    )
}
