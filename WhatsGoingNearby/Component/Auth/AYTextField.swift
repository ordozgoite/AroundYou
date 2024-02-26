//
//  AYTextField.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import SwiftUI

struct AYTextField: View {
    
    var imageName: String
    var title: LocalizedStringKey
    @Binding var error: LocalizedStringKey?
    @Binding var inputText: String
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Icon()
                
                TextInput()
            }
            
            Error()
        }
    }
    
    //MARK: - Icon
    
    @ViewBuilder
    private func Icon() -> some View {
        Image(systemName: imageName)
            .foregroundColor(.gray)
            .frame(width: 32)
            .padding(.trailing, 8)
    }
    
    //MARK: - Text Input
    
    @ViewBuilder
    private func TextInput() -> some View {
        VStack {
            TextField(title, text: $inputText)
                .textInputAutocapitalization(.never)
            
            Rectangle()
                .fill(.gray)
                .frame(height: 2)
                .opacity(0.5)
        }
    }
    
    //MARK: - Error
    
    @ViewBuilder
    private func Error() -> some View {
        HStack {
            Text(error ?? "")
                .foregroundColor(.red)
            
            Spacer()
        }
        .padding(.leading, 40)
    }
}

#Preview {
    AYTextField(imageName: "envelope.fill", title: "E-mail", error: .constant("Error"), inputText: .constant(""))
}
