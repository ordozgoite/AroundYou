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
        case taskRunCount
        case currentUserUid
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
    
    public static var taskRunCount: Int {
        get {
            return UserDefaults.standard.integer(forKey: Keys.taskRunCount.rawValue)
        }
        set(newValue) {
            UserDefaults.standard.set(newValue, forKey: Keys.taskRunCount.rawValue)
        }
    }
}
