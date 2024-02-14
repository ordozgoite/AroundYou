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
                //                PsiTextField(textInput: $authVM.nameInput, error: $authVM.errorMessage.0, placeholder: "nome", isSecret: false, imageSystemName: "person", isEmail: false)
            }
            
            //            PsiTextField(textInput: $authVM.emailInput, error: $authVM.errorMessage.1, placeholder: "e-mail", isSecret: false, imageSystemName: "envelope", isEmail: true)
            
            //            PsiTextField(textInput: $authVM.passwordInput, error: $authVM.errorMessage.2, placeholder: "senha", isSecret: true, imageSystemName: "lock", isEmail: false)
            
            if authVM.flow == .signUp {
                //                PsiTextField(textInput: $authVM.confirmPasswordInput, error: $authVM.errorMessage.3, placeholder: "confirmar senha", isSecret: true, imageSystemName: "lock", isEmail: false)
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
