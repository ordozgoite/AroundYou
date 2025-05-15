//
//  LocalState.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 21/02/24.
//

import Foundation

public class LocalState {
    
    private enum Keys: String {
        case userRegistrationToken
        case lastNotificationTime
        case isPostLocationVisible
        case hasCompletedOnboarding
        case preferredLanguage
        case agreedWithDiscoverDisclaimer
        
        // User Profile
        case currentUserUid
        case username
        case name
        case profilePic
        case biography
        case isUserInfoFetched
    }
    
    public static var userRegistrationToken: String {
        get {
            return UserDefaults.standard.string(forKey: Keys.userRegistrationToken.rawValue) ?? ""
        }
        set(newValue) {
            UserDefaults.standard.set(newValue, forKey: Keys.userRegistrationToken.rawValue)
        }
    }
    
    public static var lastNotificationTime: Int {
        get {
            return UserDefaults.standard.integer(forKey: Keys.lastNotificationTime.rawValue)
        }
        set(newValue) {
            UserDefaults.standard.set(newValue, forKey: Keys.lastNotificationTime.rawValue)
        }
    }
    
    public static var isPostLocationVisible: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Keys.isPostLocationVisible.rawValue)
        }
        set(newValue) {
            UserDefaults.standard.set(newValue, forKey: Keys.isPostLocationVisible.rawValue)
        }
    }
    
    public static var hasCompletedOnboarding: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Keys.hasCompletedOnboarding.rawValue)
        }
        set(newValue) {
            UserDefaults.standard.set(newValue, forKey: Keys.hasCompletedOnboarding.rawValue)
        }
    }
    
    public static var preferredLanguage: String {
        get {
            return UserDefaults.standard.string(forKey: Keys.preferredLanguage.rawValue) ?? "en-US"
        }
        set(newValue) {
            UserDefaults.standard.set(newValue, forKey: Keys.preferredLanguage.rawValue)
        }
    }
    
    public static var agreedWithDiscoverDisclaimer: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Keys.agreedWithDiscoverDisclaimer.rawValue)
        }
        set(newValue) {
            UserDefaults.standard.set(newValue, forKey: Keys.agreedWithDiscoverDisclaimer.rawValue)
        }
    }
    
    // MARK: - User Profile
    
    public static var currentUserUid: String {
        get {
            return UserDefaults.standard.string(forKey: Keys.currentUserUid.rawValue) ?? ""
        }
        set(newValue) {
            UserDefaults.standard.set(newValue, forKey: Keys.currentUserUid.rawValue)
        }
    }
    
    public static var username: String {
        get {
            return UserDefaults.standard.string(forKey: Keys.username.rawValue) ?? ""
        }
        set(newValue) {
            UserDefaults.standard.set(newValue, forKey: Keys.username.rawValue)
        }
    }
    
    public static var name: String {
        get {
            return UserDefaults.standard.string(forKey: Keys.name.rawValue) ?? ""
        }
        set(newValue) {
            UserDefaults.standard.set(newValue, forKey: Keys.name.rawValue)
        }
    }
    
    public static var profilePic: String {
        get {
            return UserDefaults.standard.string(forKey: Keys.profilePic.rawValue) ?? ""
        }
        set(newValue) {
            UserDefaults.standard.set(newValue, forKey: Keys.profilePic.rawValue)
        }
    }
    
    public static var biography: String {
        get {
            return UserDefaults.standard.string(forKey: Keys.biography.rawValue) ?? ""
        }
        set(newValue) {
            UserDefaults.standard.set(newValue, forKey: Keys.biography.rawValue)
        }
    }
    
    public static var isUserInfoFetched: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Keys.isUserInfoFetched.rawValue)
        }
        set(newValue) {
            UserDefaults.standard.set(newValue, forKey: Keys.isUserInfoFetched.rawValue)
        }
    }
}
