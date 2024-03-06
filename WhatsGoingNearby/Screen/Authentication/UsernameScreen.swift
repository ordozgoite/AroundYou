//
//  UsernameScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 02/03/24.
//

import SwiftUI

struct UsernameScreen: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @FocusState private var authInputIsFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    Spacer()
                    
                    AYTextField(imageName: "person.fill", title: "Choose a username...", error: $authVM.errorMessage.0, inputText: $authVM.usernameInput)
                        .focused($authInputIsFocused)
                        .onChange(of: authVM.usernameInput) { newValue in
                            if newValue.count > Constants.maxUsernameLenght {
                                authVM.usernameInput = String(newValue.prefix(Constants.maxUsernameLenght))
                            }
                        }
                    
                    Spacer()
                    
                    AYButton(title: "Done") {
                        print("👉 Botão apertado!")
                        Task {
                            let token = try await authVM.getFirebaseToken()
                            await authVM.postNewUser(username: authVM.usernameInput, name: nil, token: token)
                        }
                    }
                }
                .padding()
                
                AYErrorAlert(message: authVM.overlayError.1, isErrorAlertPresented: $authVM.overlayError.0)
            }
            .navigationTitle("Username")
        }
    }
}

#Preview {
    UsernameScreen()
        .environmentObject(AuthenticationViewModel())
}
