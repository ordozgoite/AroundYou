//
//  AYPhoneNumberTextField.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 12/03/25.
//

import SwiftUI
import PhoneNumberKit

/*
 Essa view foi depreciada, pois entendemos que não há a necessidade de usar o código do país, tampouco exibir sua bandeira, para atingir o nosso propósito atual (WhatsApp e número de telefone). Resolvemos manter o campo de texto padrão para o usuário digitar o seu número livremente.
 */

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
            
            if currentText.isEmpty {
                parent.text = ""
                textField.text = ""
                return
            }
            
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
        textField.withPrefix = true
        textField.withFlag = true
        
        return textField
    }
    
    func updateUIView(_ uiView: PhoneNumberTextField, context: Context) {
        if text.isEmpty {
            uiView.text = ""
        } else if !text.hasPrefix("+") {
            uiView.text = "+" + text
            text = "+" + text
        }
    }
}

struct AYPhoneNumberTextField: View {
    @Binding var number: String
    let placeholder: String.LocalizationValue
    
    var body: some View {
        VStack {
            PhoneNumberTextFieldView(
                text: $number,
                placeholder: String(localized: placeholder)
            )
        }
    }
}

#Preview {
    AYPhoneNumberTextField(number: .constant(""), placeholder: "Phone number")
}
