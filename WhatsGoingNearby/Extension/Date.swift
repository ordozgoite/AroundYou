//
//  Date.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import Foundation

/// Reaproveitado entre todas as bolhas: criar um `DateFormatter` por mensagem sai caro
/// numa lista de conversa.
private let messageBubbleTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale.current
    formatter.setLocalizedDateFormatFromTemplate("jmm")
    return formatter
}()

extension Date {
    /// Horário curto exibido dentro da bolha (ex.: "23:07"), no formato de 12h ou 24h
    /// conforme a preferência do sistema.
    func formatTimeToMessageBubble() -> String {
        return messageBubbleTimeFormatter.string(from: self)
    }

    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    func convertDateToString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.dateStyle = .short
        return dateFormatter.string(from: self)
    }
    
    func formatDatetoPost() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm · dd/MM/yy"
        dateFormatter.locale = Locale(identifier: "pt_BR") // Define o local para exibição no formato desejado
        
        return dateFormatter.string(from: self)
    }
    
    func formatDatetoMessage() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM, HH:mm"
        dateFormatter.locale = Locale(identifier: "pt_BR") // Define o local para exibição no formato desejado
        
        return dateFormatter.string(from: self)
    }
}
