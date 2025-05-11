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
    let placeholder: LocalizedStringKey
    
    var body: some View {
        VStack {
            PhoneNumberTextFieldView(text: $number, placeholder: placeholder.stringKey)
        }
    }
}

#Preview {
    AYPhoneNumberTextField(number: .constant(""), placeholder: "Phone number")
}
