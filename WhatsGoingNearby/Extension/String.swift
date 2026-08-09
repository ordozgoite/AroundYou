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
    
    /// O emoji desta mensagem quando ela é só isso — um emoji e mais nada.
    ///
    /// O envio não apara a mensagem, então o espaço acidental antes ou depois do emoji não
    /// pode custar o layout grande. Quem desenha usa este mesmo `Character` em vez do
    /// `first` da string crua, senão " 😀" renderizaria o espaço.
    var singleEmoji: Character? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count == 1, let character = trimmed.first, character.isEmoji else { return nil }
        return character
    }

    var isSingleEmoji: Bool { singleEmoji != nil }

    var containsEmoji: Bool { contains { $0.isEmoji } }
    
    func normalizePhoneNumber() -> String {
        return self.filter { $0.isNumber }
    }
}
