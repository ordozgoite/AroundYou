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
            .padding(.horizontal, 4)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray, lineWidth: 1)
            )
            
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
