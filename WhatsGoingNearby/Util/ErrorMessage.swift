//
//  ErrorMessage.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 15/02/24.
//

import Foundation
import SwiftUI

struct ErrorMessage {
    
    static let defaultErrorMessage: LocalizedStringKey = "Oops! Looks like something went wrong."
    static let invalidUsernameMessage: LocalizedStringKey = "The username you have chosen contains invalid characters. Please try another."
    static let usernameInUseMessage: LocalizedStringKey = "This username isn't available. Please try another."
    static let commentDistanceLimitExceededErrorMessage: LocalizedStringKey = "Sorry, you're too far away to comment on this post."
    static let selectPhotoErrorMessage: LocalizedStringKey = "Error trying to select photo."
}
