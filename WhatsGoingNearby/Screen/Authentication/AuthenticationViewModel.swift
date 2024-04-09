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
import SwiftUI

enum AuthenticationState {
    case unauthenticated
    case authenticating
    case authenticated
}

enum AuthenticationFlow: Int, CaseIterable {
    case login
    case signUp
    
    var title: LocalizedStringKey {
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
    
    @Published var usernameInput: String = ""
    @Published var emailInput: String = ""
    @Published var passwordInput: String = ""
    @Published var flow: AuthenticationFlow = .login
    @Published var isValid  = false
    @Published var authenticationState: AuthenticationState = .unauthenticated
    @Published var overlayError: (Bool, LocalizedStringKey) = (false, "")
    @Published var user: User?
    
    @Published var username: String = ""
    @Published var name: String?
    @Published var profilePic: String?
    @Published var biography: String?
    @Published var isUserInfoFetched: Bool = false
    @Published var isLoading: Bool = false
    @Published var isForgotPasswordScreenDisplayed: Bool = false
    @Published var errorMessage: (LocalizedStringKey?, LocalizedStringKey?, LocalizedStringKey?, LocalizedStringKey?) = (nil, nil, nil, nil)
    
    init() {
        registerAuthStateHandler()
        
        $flow
            .combineLatest($emailInput, $passwordInput)
            .map { flow, email, password in
                flow == .login
                ? !(email.isEmpty || password.isEmpty)
                : !(email.isEmpty || password.isEmpty)
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
            print("❌ Error: \(failure)")
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
            overlayError = (true, LocalizedStringKey(stringLiteral: error.localizedDescription))
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
            overlayError = (true, LocalizedStringKey(stringLiteral: error.localizedDescription))
            authenticationState = .unauthenticated
            return false
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            authenticationState = .unauthenticated
            resetUserInfo()
            resetInputs()
        }
        catch {
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
    }
    
    func deleteAccount() async -> Bool {
        do {
            let isUserDeleted = try await deleteUser()
            if !isUserDeleted { return false }
            
            try await user?.delete()
            authenticationState = .unauthenticated
            resetUserInfo()
            resetInputs()
            return true
        }
        catch {
            overlayError = (true, ErrorMessage.defaultErrorMessage)
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
            overlayError = (true, ErrorMessage.defaultErrorMessage)
            self.isLoading = false
            return false
        }
    }
}

//MARK: - AY Methods

extension AuthenticationViewModel {
    func postNewUser(username: String, name: String?, token: String) async -> Bool {
        let result = await AYServices.shared.postNewUser(username: username, name: name, userRegistrationToken: LocalState.userRegistrationToken, token: token)
        
        switch result {
        case .success(let user):
            updateCurrentInformation(for: user)
        case .failure(let error):
            if error == .conflict {
                overlayError = (true, ErrorMessage.usernameInUseMessage)
                return true
            } else {
                signOut()
                overlayError = (true, ErrorMessage.defaultErrorMessage)
            }
        }
        return false
    }
    
    func getUserInfo(token: String) async -> Bool {
        let result = await AYServices.shared.getUserInfo(userRegistrationToken: LocalState.userRegistrationToken.isEmpty ? nil : LocalState.userRegistrationToken, preferredLanguage: getPreferredLanguage(), token: token)
        
        switch result {
        case .success(let user):
            updateCurrentInformation(for: user)
        case .failure(let error):
            if error == .dataNotFound {
                if usernameInput.isEmpty {
                    return true
                } else {
                    let isUsernameConflict = await postNewUser(username: usernameInput, name: nil, token: token)
                    if isUsernameConflict { return true }
                }
            } else if error == .forbidden {
                signOut()
                overlayError = (true, ErrorMessage.permaBannedErrorMessage)
            } else if error == .unauthorized {
                await getUserBanExpirationDate(token: token)
            } else {
                signOut()
                overlayError = (true, ErrorMessage.defaultErrorMessage)
            }
        }
        return false
    }
    
    private func deleteUser() async throws -> Bool {
        let token = try await getFirebaseToken()
        let result = await AYServices.shared.deleteUser(token: token)
        
        switch result {
        case .success:
            return true
        case .failure:
            return false
        }
    }
    
    private func updateCurrentInformation(for user: MongoUser) {
        LocalState.currentUserUid = user.userUid
        self.username = user.username
        self.name = user.name ?? ""
        self.profilePic = user.profilePic
        self.biography = user.biography
        self.isUserInfoFetched = true
    }
    
    private func getUserBanExpirationDate(token: String) async {
        let result = await AYServices.shared.getUserBanExpireDate(token: token)
        
        switch result {
        case .success(let expirationDate):
            signOut()
            overlayError = (true, ErrorMessage.getTempBannedErrorMessage(expirationDate: expirationDate.banExpirationDateTime))
        case .failure:
            signOut()
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
    }
    
    func isLoginInputValid() -> Bool {
        errorMessage = (nil, nil, nil, nil)
        if emailInput.isEmpty { errorMessage.2 = "Please enter your email." }
        if passwordInput.isEmpty { errorMessage.3 = "Please enter your password." }
        let (_, b, c, _) = errorMessage
        return b == nil && c == nil ? true : false
    }

    func isSignupInputValid() -> Bool {
        errorMessage = (nil, nil, nil, nil)
        if usernameInput.isEmpty { errorMessage.0 = "Please enter your username." }
        if emailInput.isEmpty { errorMessage.2 = "Please enter your email." }
        if passwordInput.isEmpty { errorMessage.3 = "Please enter your password." }
        let (a, b, c, d) = errorMessage
        return a == nil && b == nil && c == nil && d == nil ? true : false
    }
    
    private func resetUserInfo() {
        username = ""
        name = nil
        profilePic = nil
        isUserInfoFetched = false
    }
    
    private func resetInputs() {
        usernameInput = ""
        emailInput = ""
        passwordInput = ""
    }
    
    private func getPreferredLanguage() -> String? {
        let preferredLanguages = Locale.preferredLanguages
        print("📚 Languages: \(preferredLanguages)")
        if let preferredLanguage = preferredLanguages.first {
            LocalState.preferredLanguage = preferredLanguage
            return preferredLanguage
        }
        return nil
    }
}
