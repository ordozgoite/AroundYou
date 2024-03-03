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
            VStack {
                Spacer()
                
                AYTextField(imageName: "person.fill", title: "Username", error: $authVM.errorMessage.0, inputText: $authVM.usernameInput)
                    .focused($authInputIsFocused)
                
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
            .navigationTitle("Choose a username")
        }
    }
}

#Preview {
    UsernameScreen()
        .environmentObject(AuthenticationViewModel())
}
