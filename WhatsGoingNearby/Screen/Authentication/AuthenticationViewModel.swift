//
//  AuthenticationViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import Foundation

enum AuthenticationFlow: Int, CaseIterable {
    case login
    case signUp
    
    var title: String {
        switch self {
        case .login:
            return "Entrar"
        case .signUp:
            return "Registrar-se"
        }
    }
}

@MainActor
class AuthenticationViewModel: ObservableObject {
    
    @Published var nameInput: String = ""
    @Published var emailInput: String = ""
    @Published var passwordInput: String = ""
    @Published var confirmPasswordInput: String = ""
    @Published var flow: AuthenticationFlow = .login
    @Published var isValid  = false
//    @Published var authenticationState: AuthenticationState = .unauthenticated
    @Published var overlayError: (Bool, String) = (false, "")
//    @Published var user: User?
    
    @Published var name: String = ""
    @Published var isAccessInfoFetched: Bool = false
    @Published var isLoading: Bool = false
    @Published var isForgotPasswordScreenDisplayed: Bool = false
    @Published var errorMessage: (String?, String?, String?, String?) = (nil, nil, nil, nil)
}
