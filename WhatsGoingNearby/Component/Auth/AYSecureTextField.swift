//
//  AYSecureTextField.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import SwiftUI

struct AYSecureTextField: View {
    
    var imageName: String
    var title: String
    @State var isSecured: Bool = true
    @Binding var error: String?
    @Binding var inputText: String
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Icon()
                
                ZStack(alignment: .trailing) {
                    TextInput()
                    
                    SecureButton()
                }
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
            if isSecured {
                SecureField(title, text: $inputText)
                    .textInputAutocapitalization(.never)
            } else {
                TextField(title, text: $inputText)
                    .textInputAutocapitalization(.never)
            }
            
            Rectangle()
                .fill(.gray)
                .frame(height: 2)
                .opacity(0.5)
        }
    }
    
    //MARK: - Secure Button
    
    @ViewBuilder
    private func SecureButton() -> some View {
        Image(systemName: self.isSecured ? "eye.slash" : "eye")
            .foregroundStyle(.gray)
            .onTapGesture {
                isSecured.toggle()
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
    AYSecureTextField(imageName: "lock.fill", title: "password", error: .constant("Error"), inputText: .constant(""))
}
