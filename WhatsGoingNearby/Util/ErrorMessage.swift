//
//  ErrorMessage.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 15/02/24.
//

import Foundation
import SwiftUI

struct ErrorMessage {
    
    static let defaultErrorMessage: LocalizedStringKey = "Oops! Looks like something went wrong. Try again later."
    static let locationDisabledErrorMessage: LocalizedStringKey = "We couldn't access your location. Please make sure to allow access in your device's settings."
    static let invalidUsernameMessage: LocalizedStringKey = "The username you have chosen contains invalid characters. Please try another."
    static let usernameInUseMessage: LocalizedStringKey = "This username isn't available. Please try another."
    static let commentDistanceLimitExceededErrorMessage: LocalizedStringKey = "Sorry, you're too far away to comment on this post."
    static let publicationLimitExceededErrorMessage: LocalizedStringKey = "Sorry, you have reached the maximum allowed number of active publications."
    static let selectPhotoErrorMessage: LocalizedStringKey = "Error trying to select photo."
    static let permaBannedErrorMessage: LocalizedStringKey = "Your account has been permanently banned."
    static let editDistanceLimitExceededErrorMessage: LocalizedStringKey = "Sorry, you're too far away to edit this post."
    
    static func getTempBannedErrorMessage(expirationDate: Int) -> LocalizedStringKey {
        return "Your account has been temporarily banned until \(expirationDate.convertTimestampToDate().convertDateToString())"
    }
}
