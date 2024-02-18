//
//  ForgotPasswordScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 17/02/24.
//

import SwiftUI

struct ForgotPasswordScreen: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @State private var displayAlert: Bool = false
    
    var body: some View {
        VStack {
            Spacer()
            
            AYTextField(imageName: "envelope", title: "E-mail", error: $authVM.errorMessage.1, inputText: $authVM.emailInput)
            
            Spacer()
            
            AYButton(title: "Send Email") {
                authVM.errorMessage = (nil, nil, nil, nil)
                Task {
                    self.displayAlert = await authVM.sendPasswordReset()
                }
            }
            .disabled(authVM.emailInput.isEmpty)
        }
        .padding()
        .navigationBarTitleDisplayMode(.large)
        .navigationTitle("Recover Password")
        .alert(isPresented: $displayAlert) {
            Alert(
                title: Text("E-mail sent! 📩"),
                message: Text("Please check your inbox.")
            )
        }
    }
}

#Preview {
    ForgotPasswordScreen()
        .environmentObject(AuthenticationViewModel())
}
