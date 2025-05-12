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
                            if newValue.count > Constants.MAX_USERNAME_LENGHT {
                                authVM.usernameInput = String(newValue.prefix(Constants.MAX_USERNAME_LENGHT))
                            }
                        }
                    
                    Spacer()
                    
                    AYButton(title: "Done") {
                        Task {
                            try await chooseUsername()
                        }
                    }
                }
                .padding()
                
                AYErrorAlert(message: authVM.overlayError.1, isErrorAlertPresented: $authVM.overlayError.0)
            }
            .navigationTitle("Username")
            .toolbar {
                ToolbarItem {
                    Button {
                        authVM.signOut()
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundStyle(.gray)
                    }
                }
            }
        }
    }
    
    //MARK: - Private Method
    
    private func chooseUsername() async throws {
        if authVM.isUsernameValid() {
            let token = try await authVM.getFirebaseToken()
            _ = await authVM.postNewUser(username: authVM.usernameInput, name: nil, token: token)
        }
    }
}

#Preview {
    UsernameScreen()
        .environmentObject(AuthenticationViewModel())
}
