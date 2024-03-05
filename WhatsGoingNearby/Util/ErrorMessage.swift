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
    static let invalidUsernameMessage: LocalizedStringKey = "Username can only contain letters and numbers."
    static let usernameInUseMessage: LocalizedStringKey = "This username isn't available. Please try another."
    static let distanceLimitExceededMessage: LocalizedStringKey = "Sorry, you're too far away to comment on this post."
}
