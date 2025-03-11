//
//  BusinessViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 11/03/25.
//

import Foundation
import SwiftUI

@MainActor
class BusinessViewModel: ObservableObject {
    
    @Published var businesses: [FormattedBusinessShowcase] = []
    @Published var isLoading: Bool = false
    @Published var overlayError: (Bool, LocalizedStringKey) = (false, "")
    
    func getBusinesses(location: Location, token: String) async {
        isLoading = true
        defer { isLoading = false }
        
        let result = await AYServices.shared.getBusinessesNearBy(location: location, token: token)
        
        switch result {
        case .success(let businesses):
            self.businesses = businesses
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
    }
}
