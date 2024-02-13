//
//  Date.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import Foundation

extension Date {
    func convertToMinutesAgo() -> String {
        let currentDate = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.minute], from: self, to: currentDate)
        
        if let minutes = components.minute {
            if minutes == 0 {
                return "Agora mesmo"
            } else if minutes == 1 {
                return "1 minuto atrás"
            } else {
                return "\(minutes) minutos atrás"
            }
        } else {
            return "Erro ao calcular a diferença de tempo"
        }
    }
}
