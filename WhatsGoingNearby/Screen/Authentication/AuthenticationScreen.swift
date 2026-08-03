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
    @StateObject private var navCoordinator = NavigationCoordinator()
    
    @State private var isEmailOptionSelected: Bool = false
    
    var body: some View {
        NavigationStack(path: $navCoordinator.path) {
            ZStack {
                VStack {
                    Header()
                    
                    EmailFieldsView()
                    
                    ActionView()
                    
                    Footer()
                }
                .padding()
                
                AYErrorAlert(message: authVM.overlayError.1 , isErrorAlertPresented: $authVM.overlayError.0)
            }
            .navigationDestination(for: AppRoute.self) { destination in
                switch destination {
                case .forgotPassword:
                    ForgotPasswordScreen()
                default:
                    EmptyView()
                }
            }
        }
    }
    
    // MARK: - Header
    
    @ViewBuilder
    private func Header() -> some View {
        VStack {
            LogoView()
            
            AuthFlowSegmentedControl(selectedFilter: $authVM.flow)
                .padding([.top, .bottom], 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    //MARK: - Logo View
    
    @ViewBuilder
    private func LogoView() -> some View {
        VStack {
            Image("logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 128)
                .foregroundStyle(.blue)
            
//            Text("Around You")
//                .foregroundStyle(.blue)
//                .font(.largeTitle)
//                .fontWeight(.bold)
        }
        .padding()
    }
    
    // MARK: - Email Fields
    
    @ViewBuilder
    private func EmailFieldsView() -> some View {
        if isEmailOptionSelected {
            VStack {
                if authVM.flow == .signUp {
                    AYTextField(imageName: "person.fill", title: "Username", error: $authVM.errorMessage.0, inputText: $authVM.usernameInput)
                        .focused($authInputIsFocused)
                }
                
                AYTextField(imageName: "envelope", title: "E-mail", error: $authVM.errorMessage.1, inputText: $authVM.emailInput)
                    .keyboardType(.emailAddress)
                    .focused($authInputIsFocused)
                
                AYSecureTextField(imageName: "lock", title: "Password", error: $authVM.errorMessage.2, inputText: $authVM.passwordInput)
                    .focused($authInputIsFocused)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
    
    // MARK: - Action View
    
    @ViewBuilder
    private func ActionView() -> some View {
        VStack {
            if isEmailOptionSelected {
                EmailAuthButton()
            } else {
                AYButton(
                    title: "Continue with Email",
                    systemNameImage: "envelope.fill"
                ) {
                    isEmailOptionSelected = true
                }
            }
            
            Or()
            
            SiwA()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }
    
    //MARK: - Button View
    
    @ViewBuilder
    private func EmailAuthButton() -> some View {
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
    
    //MARK: - SiwA
    
    @ViewBuilder
    private func SiwA() -> some View {
        if self.colorScheme == .light {
            SiwAButton()
                .signInWithAppleButtonStyle(.black)
        } else {
            SiwAButton()
                .signInWithAppleButtonStyle(.white)
        }
    }
    
    //MARK: - SiwA Button
    
    @ViewBuilder
    private func SiwAButton() -> some View {
        SignInWithAppleButton(.continue) { request in
            authVM.handleSignInWithAppleRequest(request)
        } onCompletion: { result in
            authVM.handleSignInWithAppleCompletion(result)
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 58, maxHeight: 58)
        .cornerRadius(29)
    }
    
    // MARK: - Footer
    
    @ViewBuilder
    private func Footer() -> some View {
        ZStack {
            if authVM.flow == .login  {
                if isEmailOptionSelected {
                    Button("Forgot your password?") {
                        navCoordinator.navigate(to: .forgotPassword)
                    }
                }
            } else {
                Text("By signing up, you agree to our [Terms of Use](https://aroundyou3.wordpress.com/terms-of-use) and [Privacy Policy](https://aroundyou3.wordpress.com/policy-privacy).")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.gray)
                    .font(.caption)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }
}

#Preview {
    AuthenticationScreen()
        .environmentObject(AuthenticationViewModel())
}
