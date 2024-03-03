//
//  AuthenticationScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import SwiftUI
import AuthenticationServices

struct AuthenticationScreen: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @Environment(\.colorScheme) var colorScheme
    @FocusState private var authInputIsFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 16) {
                    LogoView()
                    
                    AuthFlowSegmentedControl(selectedFilter: $authVM.flow)
                        .padding([.top, .bottom], 16)
                    
                    Spacer()
                    
                    if authVM.flow == .signUp {
                        AYTextField(imageName: "person.fill", title: "Username", error: $authVM.errorMessage.0, inputText: $authVM.fullNameInput)
                            .focused($authInputIsFocused)
                        
                        AYTextField(imageName: "person.fill", title: "Full name", error: $authVM.errorMessage.0, inputText: $authVM.fullNameInput)
                            .textInputAutocapitalization(.words)
                            .focused($authInputIsFocused)
                    }
                    
                    AYTextField(imageName: "envelope", title: "E-mail", error: $authVM.errorMessage.1, inputText: $authVM.emailInput)
                        .keyboardType(.emailAddress)
                        .focused($authInputIsFocused)
                    
                    AYSecureTextField(imageName: "lock", title: "Password", error: $authVM.errorMessage.2, inputText: $authVM.passwordInput)
                        .focused($authInputIsFocused)
                    
                    Spacer()
                    
                    ButtonView()
                    
                    Or()
                    
                    SiwAButton()
                    
                    if authVM.flow == .login  {
                        Button("Forgot your password?") {
                            authVM.isForgotPasswordScreenDisplayed = true
                        }
                    }
                }
                .padding()
                
                AYErrorAlert(message: authVM.overlayError.1 , isErrorAlertPresented: $authVM.overlayError.0)
                
                NavigationLink(
                    destination: ForgotPasswordScreen().environmentObject(authVM),
                    isActive: $authVM.isForgotPasswordScreenDisplayed,
                    label: { EmptyView() }
                )
            }
        }
    }
    
    //MARK: - Logo View
    
    @ViewBuilder
    private func LogoView() -> some View {
        VStack {
            Image(systemName: "location.circle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 100)
                .foregroundStyle(.blue)
            
            Text("Around You")
                .foregroundStyle(.blue)
                .font(.largeTitle)
                .fontWeight(.bold)
        }
        .padding()
    }
    
    //MARK: - Button View
    
    @ViewBuilder
    private func ButtonView() -> some View {
        if authVM.authenticationState == .authenticating {
            AYProgressButton(title: "Authenticating...")
        } else {
            AYButton(title: authVM.flow.title) {
                authInputIsFocused = false
                Task {
                    switch authVM.flow {
                    case .login:
                        if authVM.isLoginInputValid() {
                            _ = await authVM.signInWithEmailPassword()
                        }
                    case .signUp:
                        if authVM.isSignupInputValid() {
                            _ = await authVM.signUpWithEmailPassword()
                        }
                    }
                }
            }
        }
    }
    
    //MARK: - Or
    
    @ViewBuilder
    private func Or() -> some View {
        HStack {
            Rectangle()
                .frame(width: screenWidth/4, height: 1)
                .foregroundStyle(.gray)
            
            Text("or")
                .foregroundStyle(.gray)
                .font(.subheadline)
            
            Rectangle()
                .frame(width: screenWidth/4, height: 1)
                .foregroundStyle(.gray)
        }
    }
    
    //MARK: - Sign in with Apple Button
    
    @ViewBuilder
    private func SiwAButton() -> some View {
        SignInWithAppleButton(.continue) { request in
            authVM.handleSignInWithAppleRequest(request)
        } onCompletion: { result in
            authVM.handleSignInWithAppleCompletion(result)
        }
        .signInWithAppleButtonStyle(colorScheme == .light ? .black : .white)
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 58, maxHeight: 58)
        .cornerRadius(10)
    }
}

#Preview {
    AuthenticationScreen()
        .environmentObject(AuthenticationViewModel())
}
