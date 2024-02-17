//
//  AYErrorAlert.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 15/02/24.
//

import SwiftUI

struct AYErrorAlert: View {
    
    let message: String
    @Binding var isErrorAlertPresented: Bool
    
    var body: some View {
        ZStack {
            VStack(spacing: 32) {
                Text("Error")
                    .font(.title)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.title3)
                    .fontWeight(.light)
                    .multilineTextAlignment(.center)
                
                Button("OK") {
                    isErrorAlertPresented = false
                }
                .foregroundStyle(.gray)
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .frame(width: screenWidth - 64, height: 240)
        .background(.thinMaterial)
        .cornerRadius(16)
    }
}

#Preview {
    AYErrorAlert(message: ErrorMessage.defaultErrorMessage, isErrorAlertPresented: .constant(true))
}
