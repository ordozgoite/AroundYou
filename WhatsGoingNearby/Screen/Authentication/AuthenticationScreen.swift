//
//  AuthenticationScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import SwiftUI

struct AuthenticationScreen: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            LogoView()
            
            AuthFlowSegmentedControl(selectedFilter: $authVM.flow)
                .padding([.top, .bottom], 16)
            
            Spacer()
            
            if authVM.flow == .signUp {
                AYTextField(imageName: "person.fill", title: "Name", error: $authVM.errorMessage.0, inputText: $authVM.nameInput)
            }
            
            AYTextField(imageName: "envelope", title: "E-mail", error: $authVM.errorMessage.1, inputText: $authVM.emailInput)
            
            AYSecureTextField(imageName: "lock", title: "Password", error: $authVM.errorMessage.2, inputText: $authVM.passwordInput)
            
            if authVM.flow == .signUp {
                AYSecureTextField(imageName: "lock", title: "Confirm password", error: $authVM.errorMessage.3, inputText: $authVM.confirmPasswordInput)
            }
            
            Spacer()
            Spacer()
            
            ButtonView()
            
            if authVM.flow == .signUp {
                TermsAndPrivacyView()
            } else {
                Button("Esqueceu a senha?") {
                    authVM.isForgotPasswordScreenDisplayed = true
                }
                .padding()
            }
        }
        .padding()
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
    
    //MARK: - Terms Service
    
    @ViewBuilder
    private func TermsAndPrivacyView() -> some View {
        VStack(alignment: .center, spacing: nil) {
            Text("Ao tocar em Registrar-se, concordo com os")
            //            .multilineTextAlignment(.center)
                .font(.callout)
                .foregroundStyle(.gray)
            
            HStack {
                Button("Termos de Serviço ") {}
                    .font(.callout)
                Text("e")
                    .font(.callout)
                    .foregroundStyle(.gray)
                Button("Política de Privacidade") {}
                    .font(.callout)
            }
        }
        .padding()
    }
    
    //MARK: - Button View
    
    @ViewBuilder
    private func ButtonView() -> some View {
        AYButton(title: authVM.flow.title) {
            // auth
        }
    }
}

#Preview {
    AuthenticationScreen()
        .environmentObject(AuthenticationViewModel())
}
