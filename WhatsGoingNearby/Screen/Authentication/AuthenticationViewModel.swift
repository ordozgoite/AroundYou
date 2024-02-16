//
//  AuthenticationViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import Foundation
import FirebaseAuth

enum AuthenticationState {
    case unauthenticated
    case authenticating
    case authenticated
}

enum AuthenticationFlow: Int, CaseIterable {
    case login
    case signUp
    
    var title: String {
        switch self {
        case .login:
            return "Enter"
        case .signUp:
            return "Register"
        }
    }
}

@MainActor
class AuthenticationViewModel: ObservableObject {
    
    @Published var nameInput: String = ""
    @Published var emailInput: String = "felipe@felipe.com" // remove it
    @Published var passwordInput: String = "felipe123" // remove it
    @Published var confirmPasswordInput: String = ""
    @Published var flow: AuthenticationFlow = .login
    @Published var isValid  = false
    @Published var authenticationState: AuthenticationState = .unauthenticated
    @Published var overlayError: (Bool, String) = (false, "")
    @Published var user: User?
    
    @Published var name: String = "Victor Rafael Ordozgoite" // remove it
    @Published var profilePic: String?
    @Published var biography: String?
    @Published var isUserInfoFetched: Bool = false
    @Published var isLoading: Bool = false
    @Published var isForgotPasswordScreenDisplayed: Bool = false
    @Published var errorMessage: (String?, String?, String?, String?) = (nil, nil, nil, nil)
    
    init() {
        registerAuthStateHandler()
        
        $flow
            .combineLatest($emailInput, $passwordInput, $confirmPasswordInput)
            .map { flow, email, password, confirmPassword in
                flow == .login
                ? !(email.isEmpty || password.isEmpty)
                : !(email.isEmpty || password.isEmpty || confirmPassword.isEmpty)
            }
            .assign(to: &$isValid)
    }
    
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    
    func registerAuthStateHandler() {
        if authStateHandler == nil {
            authStateHandler = Auth.auth().addStateDidChangeListener { auth, user in
                self.user = user
                self.authenticationState = user == nil ? .unauthenticated : .authenticated
            }
        }
    }
    
    func getFirebaseToken() async throws -> String {
        return try await user?.getIDToken() ?? ""
    }
}

//MARK: - Email and Password Authentication

extension AuthenticationViewModel {
    func signInWithEmailPassword() async -> Bool {
        authenticationState = .authenticating
        do {
            let authResult = try await Auth.auth().signIn(withEmail: self.emailInput, password: self.passwordInput)
            user = authResult.user
            print("🤝 User \(authResult.user.uid) signed in.")
            return true
        }
        catch  {
            print(error)
            overlayError = (true, error.localizedDescription)
            authenticationState = .unauthenticated
            return false
        }
    }
    
    func signUpWithEmailPassword() async -> Bool {
        authenticationState = .authenticating
        do  {
            let authResult = try await Auth.auth().createUser(withEmail: emailInput, password: passwordInput)
            user = authResult.user
            print("🤝 User \(authResult.user.uid) signed in.")
            return true
        }
        catch {
            print(error)
            overlayError = (true, error.localizedDescription)
            authenticationState = .unauthenticated
            return false
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            authenticationState = .unauthenticated
            resetUserInfo()
        }
        catch {
            overlayError = (true, error.localizedDescription)
        }
    }
    
    func deleteAccount() async -> Bool {
        do {
            try await user?.delete()
            return true
        }
        catch {
            overlayError = (true, error.localizedDescription)
            return false
        }
    }
    
    func sendPasswordReset() async -> Bool {
        self.isLoading = true
        do {
            try await Auth.auth().sendPasswordReset(withEmail: emailInput)
            self.isLoading = false
            return true
        } catch {
            overlayError = (true, error.localizedDescription)
            self.isLoading = false
            return false
        }
    }
}

//MARK: - AY Methods

extension AuthenticationViewModel {
    func postNewUser(token: String) async {
        let result = await AYServices.shared.postNewUser(name: nameInput, token: token)
        
        switch result {
        case .success(let user):
            name = user.name
            isUserInfoFetched = true
        case .failure(let error):
            overlayError = (true, error.customMessage)
        }
    }
    
    func getUserInfo(token: String) async {
        let result = await AYServices.shared.getUserInfo(token: token)
        
        switch result {
        case .success(let user):
            name = user.name
            profilePic = user.profilePic
            biography = user.biography
            isUserInfoFetched = true
        case .failure(let error):
            print("❌ Error: \(error)")
            signOut()
            overlayError = (true, error.customMessage)
        }
    }
    
    func isLoginInputValid() -> Bool {
        errorMessage = (nil, nil, nil, nil)
        if emailInput.isEmpty { errorMessage.1 = "Por favor insira seu e-mail." }
        if passwordInput.isEmpty { errorMessage.2 = "Por favor insira sua senha." }
        let (_, b, c, _) = errorMessage
        return b == nil && c == nil ? true : false
    }
    
    func isSignupInputValid() -> Bool {
        errorMessage = (nil, nil, nil, nil)
        if nameInput.isEmpty { errorMessage.0 = "Por favor insira seu nome." }
        if emailInput.isEmpty { errorMessage.1 = "Por favor insira seu e-mail." }
        if passwordInput.isEmpty { errorMessage.2 = "Por favor insira sua senha." }
        if confirmPasswordInput != passwordInput { errorMessage.3 = "Suas senhas não combinam." }
        if confirmPasswordInput.isEmpty { errorMessage.3 = "Por favor confirme sua senha." }
        let (a, b, c, d) = errorMessage
        return a == nil && b == nil && c == nil && d == nil ? true : false
    }
    
    private func resetUserInfo() {
        name = ""
        profilePic = nil
        isUserInfoFetched = false
    }
}
