//
//  PublishBusinessViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 02/03/25.
//

import Foundation
import SwiftUI

@MainActor
class PublishBusinessViewModel: ObservableObject {
    
    @Published var nameInput: String = ""
    @Published var descriptionInput: String = ""
    @Published var selectedCategory: BusinessCategory? = nil
    @Published var isLoading: Bool = false
    
    func publishBusiness() async throws {
        // TODO: Post new Business
    }
}
