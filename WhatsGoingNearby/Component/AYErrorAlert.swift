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
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                
                Text(message)
                    .fontWeight(.light)
                    .foregroundStyle(.white)
                
                Text("OK")
                    .font(.title3)
                    .fontWeight(.black)
                    .foregroundStyle(.white)
                    .onTapGesture {
                        isErrorAlertPresented = false
                    }
            }
        }
        .frame(width: 256, height: 176)
        .background(.thinMaterial)
        .cornerRadius(16)
    }
}

#Preview {
    AYErrorAlert(message: "An error ocurred.", isErrorAlertPresented: .constant(true))
}
