//
//  AYPhoneNumberTextField.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 12/03/25.
//

import SwiftUI
import PhoneNumberKit

struct PhoneNumberTextFieldView: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: PhoneNumberTextFieldView
        
        init(parent: PhoneNumberTextFieldView) {
            self.parent = parent
        }
        
        @objc func textFieldDidChange(_ textField: UITextField) {
            var currentText = textField.text ?? ""
            
            // Garante que o "+" esteja sempre presente no início
            if !currentText.hasPrefix("+") {
                currentText = "+" + currentText
            }
            
            parent.text = currentText
            textField.text = currentText
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    func makeUIView(context: Context) -> PhoneNumberTextField {
        let textField = PhoneNumberTextField()
        textField.delegate = context.coordinator
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldDidChange(_:)), for: .editingChanged)
        textField.placeholder = placeholder
        textField.withPrefix = true  // Exibe o prefixo do país
        textField.withFlag = true    // Exibe a bandeira do país
        textField.text = text.isEmpty ? "+" : text // Garante que inicie com "+"
        return textField
    }
    
    func updateUIView(_ uiView: PhoneNumberTextField, context: Context) {
        if !uiView.text!.hasPrefix("+") {
            uiView.text = "+" + uiView.text!
        }
    }
}



struct AYPhoneNumberTextField: View {
    
    @Binding var number: String
    let placeholder: String
    
    var body: some View {
        VStack {
            PhoneNumberTextFieldView(text: $number, placeholder: placeholder)
        }
        .onAppear {
            addRegionCode()
        }
    }
    
    private func addRegionCode() {
//        let phoneNumberKit = PhoneNumberUtility()
//        
//        // Verifica se já há um código no número, para não sobrescrever
//        guard number.isEmpty else { return }
//        
//        if let regionCode = phoneNumberKit.code,
//           let countryCode = phoneNumberKit.countryCode(for: regionCode) {
//            self.number = "+\(countryCode)"
//        } else {
//            self.number = "+"  // Fallback se não conseguir detectar o país
//        }
    }
}

#Preview {
    AYPhoneNumberTextField(number: .constant(""), placeholder: "Phone number")
}
