//
//  AuthenticationViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import Foundation
import FirebaseAuth
import AuthenticationServices
import CryptoKit

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
    @Published var emailInput: String = ""
    @Published var passwordInput: String = ""
    @Published var confirmPasswordInput: String = ""
    @Published var flow: AuthenticationFlow = .login
    @Published var isValid  = false
    @Published var authenticationState: AuthenticationState = .unauthenticated
    @Published var overlayError: (Bool, String) = (false, "")
    @Published var user: User?
    
    @Published var name: String = ""
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
    
    private var currentNonce: String?
    
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

//MARK: - Sign in with Apple

extension AuthenticationViewModel {
    func handleSignInWithAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
        let nonce = randomNonceString()
        currentNonce = nonce
        request.nonce = sha256(nonce)
    }
    
    func handleSignInWithAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        if case .failure(let failure) = result {
            overlayError = (true, failure.localizedDescription)
        }
        else if case .success(let authorization) = result {
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                guard let nonce = currentNonce else {
                    fatalError("Invalid state: a login callback was received, but no login request was sent.")
                }
                guard let appleIDToken = appleIDCredential.identityToken else {
                    print("Unable to fetch identify token.")
                    return
                }
                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                    print("Unable to serialise token string from data: \(appleIDToken.debugDescription)")
                    return
                }
                
                let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: nonce)
                Task {
                    do {
                        _ = try await Auth.auth().signIn(with: credential)
                        if let name = appleIDCredential.fullName?.givenName {
                            print("🙋‍♂️ NAME: \(name)")
                            self.name = name
                        }
                    }
                    catch {
                        print("Error authenticating: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError(
                        "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
                    )
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
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
            self.name = nameInput
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
            authenticationState = .unauthenticated
            resetUserInfo()
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
    func postNewUser(token: String, name: String) async {
        let result = await AYServices.shared.postNewUser(name: name, userRegistrationToken: LocalState.userRegistrationToken, token: token)
        
        switch result {
        case .success(let user):
            self.name = user.name
            isUserInfoFetched = true
        case .failure(let error):
            signOut()
            overlayError = (true, error.customMessage)
        }
    }
    
    func getUserInfo(token: String) async {
        let result = await AYServices.shared.getUserInfo(userRegistrationToken: LocalState.userRegistrationToken.isEmpty ? nil : LocalState.userRegistrationToken, token: token)
        
        switch result {
        case .success(let user):
            LocalState.currentUserUid = user.userUid
            name = user.name
            profilePic = user.profilePic
            biography = user.biography
            isUserInfoFetched = true
        case .failure(let error):
            print("❌ Error: \(error)")
            if error == .dataNotFound {
                await postNewUser(token: token, name: self.name)
            } else {
                signOut()
                overlayError = (true, error.customMessage)
            }
        }
    }
    
    func isLoginInputValid() -> Bool {
        errorMessage = (nil, nil, nil, nil)
        if emailInput.isEmpty { errorMessage.1 = "Please enter your email." }
        if passwordInput.isEmpty { errorMessage.2 = "Please enter your password." }
        let (_, b, c, _) = errorMessage
        return b == nil && c == nil ? true : false
    }

    func isSignupInputValid() -> Bool {
        errorMessage = (nil, nil, nil, nil)
        if nameInput.isEmpty { errorMessage.0 = "Please enter your name." }
        if emailInput.isEmpty { errorMessage.1 = "Please enter your email." }
        if passwordInput.isEmpty { errorMessage.2 = "Please enter your password." }
        if confirmPasswordInput != passwordInput { errorMessage.3 = "Your passwords do not match." }
        if confirmPasswordInput.isEmpty { errorMessage.3 = "Please confirm your password." }
        let (a, b, c, d) = errorMessage
        return a == nil && b == nil && c == nil && d == nil ? true : false
    }
    
    private func resetUserInfo() {
        name = ""
        profilePic = nil
        isUserInfoFetched = false
    }
}
