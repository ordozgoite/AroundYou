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
        case currentUserUid
        case lastNotificationTime
        case isPostLocationVisible
        case hasCompletedOnboarding
        case preferredLanguage
        case agreedWithDiscoverDisclaimer
    }
    
    public static var userRegistrationToken: String {
        get {
            return UserDefaults.standard.string(forKey: Keys.userRegistrationToken.rawValue) ?? ""
        }
        set(newValue) {
            UserDefaults.standard.set(newValue, forKey: Keys.userRegistrationToken.rawValue)
        }
    }
    
    public static var currentUserUid: String {
        get {
            return UserDefaults.standard.string(forKey: Keys.currentUserUid.rawValue) ?? ""
        }
        set(newValue) {
            UserDefaults.standard.set(newValue, forKey: Keys.currentUserUid.rawValue)
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
}
