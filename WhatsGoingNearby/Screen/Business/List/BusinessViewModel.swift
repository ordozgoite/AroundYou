//
//  BusinessViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 11/03/25.
//

import Foundation
import SwiftUI

enum BusinessError: Error {
    case deletionFailed
}

@MainActor
class BusinessViewModel: ObservableObject {
    
    @Published var businesses: [FormattedBusinessShowcase] = []
    @Published var userBusinesses: [FormattedBusinessShowcase]? = nil
    @Published var isFetchingBusinessesNearBy: Bool = false
    @Published var initialBusinessesFetched: Bool = false
    @Published var isFetchingUserBusinesses: Bool = false
    @Published var isBusinessLimitErrorPopoverDisplayed: Bool = false
    @Published var isPublishBusinessScreenDisplayed: Bool = false
    @Published var isMyBusinessViewDisplayed: Bool = false
    @Published var timer: Timer?
    @Published var overlayError: (Bool, LocalizedStringKey) = (false, "")
    
    func getBusinesses(fromLocation location: Location, token: String) async {
        if !initialBusinessesFetched { isFetchingBusinessesNearBy = true }
        defer { isFetchingBusinessesNearBy = false }
        
        let result = await AYServices.shared.getBusinessesNearBy(location: location, token: token)
        
        switch result {
        case .success(let businesses):
            initialBusinessesFetched = true
            self.businesses = businesses
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
    }
    
    func getBusinessByUser(withLocation location: Location, token: String) async {
        if !initialBusinessesFetched { isFetchingUserBusinesses = true }
        defer { isFetchingUserBusinesses = false }
        
        let result = await AYServices.shared.getBusinessByUser(location: location, token: token)
        
        switch result {
        case .success(let businesses):
            self.userBusinesses = businesses
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
    }
    
    func deleteBusiness(businessId: String, token: String) async throws {
        let result = await AYServices.shared.deleteBusiness(businessId: businessId, token: token)
        
        switch result {
        case .success:
            removeBusiness(withId: businessId)
        case .failure:
            overlayError = (true, ErrorMessage.defaultErrorMessage)
            throw BusinessError.deletionFailed
        }
    }
    
    private func removeBusiness(withId businessId: String) {
        self.businesses.removeAll { $0.id == businessId }
        self.userBusinesses?.removeAll { $0.id == businessId }
    }
}
