//
//  LocalState.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 21/02/24.
//

import Foundation
import CoreLocation

public class LocalState {
    
    private enum Keys: String {
        case userRegistrationToken
        case lastNotificationTime
        case bgTaskScheduledCount
        case bgTaskRunCount
        case bgTaskErrorCount
        case engagementNotificationCount
        case lastLocationLatitude
        case lastLocationLongitude
        case lastLocationTimestamp
        case lastLocationAccuracy
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
    
    public static var bgTaskScheduledCount: Int {
        get {
            return UserDefaults.standard.integer(forKey: Keys.bgTaskScheduledCount.rawValue)
        }
        set(newValue) {
            UserDefaults.standard.set(newValue, forKey: Keys.bgTaskScheduledCount.rawValue)
        }
    }

    public static var bgTaskRunCount: Int {
        get {
            return UserDefaults.standard.integer(forKey: Keys.bgTaskRunCount.rawValue)
        }
        set(newValue) {
            UserDefaults.standard.set(newValue, forKey: Keys.bgTaskRunCount.rawValue)
        }
    }

    public static var bgTaskErrorCount: Int {
        get {
            return UserDefaults.standard.integer(forKey: Keys.bgTaskErrorCount.rawValue)
        }
        set(newValue) {
            UserDefaults.standard.set(newValue, forKey: Keys.bgTaskErrorCount.rawValue)
        }
    }

    public static var engagementNotificationCount: Int {
        get {
            return UserDefaults.standard.integer(forKey: Keys.engagementNotificationCount.rawValue)
        }
        set(newValue) {
            UserDefaults.standard.set(newValue, forKey: Keys.engagementNotificationCount.rawValue)
        }
    }

    public static func saveLastKnownLocation(_ location: CLLocation) {
        UserDefaults.standard.set(location.coordinate.latitude, forKey: Keys.lastLocationLatitude.rawValue)
        UserDefaults.standard.set(location.coordinate.longitude, forKey: Keys.lastLocationLongitude.rawValue)
        UserDefaults.standard.set(location.timestamp.timeIntervalSince1970, forKey: Keys.lastLocationTimestamp.rawValue)
        UserDefaults.standard.set(location.horizontalAccuracy, forKey: Keys.lastLocationAccuracy.rawValue)
    }

    public static func lastKnownLocation(
        maxAge: TimeInterval,
        maximumAccuracy: CLLocationAccuracy
    ) -> CLLocation? {
        let defaults = UserDefaults.standard
        guard
            defaults.object(forKey: Keys.lastLocationLatitude.rawValue) != nil,
            defaults.object(forKey: Keys.lastLocationLongitude.rawValue) != nil,
            defaults.object(forKey: Keys.lastLocationTimestamp.rawValue) != nil
        else { return nil }

        let latitude = defaults.double(forKey: Keys.lastLocationLatitude.rawValue)
        let longitude = defaults.double(forKey: Keys.lastLocationLongitude.rawValue)
        let timestamp = Date(timeIntervalSince1970: defaults.double(forKey: Keys.lastLocationTimestamp.rawValue))
        let accuracy = defaults.double(forKey: Keys.lastLocationAccuracy.rawValue)
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let age = Date().timeIntervalSince(timestamp)

        guard
            CLLocationCoordinate2DIsValid(coordinate),
            age >= -60,
            age <= maxAge,
            accuracy >= 0,
            accuracy <= maximumAccuracy
        else { return nil }

        return CLLocation(
            coordinate: coordinate,
            altitude: 0,
            horizontalAccuracy: accuracy,
            verticalAccuracy: -1,
            timestamp: timestamp
        )
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
