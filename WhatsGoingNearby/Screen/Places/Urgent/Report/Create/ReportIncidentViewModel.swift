//
//  ReportIncidentViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 09/04/25.
//

import SwiftUI
import PhotosUI

enum PostReportIncidentError: Error {
    case genericError
}

@MainActor
class ReportIncidentViewModel: ObservableObject {
    @Published var selectedReportType: IncidentType?
    @Published var isUserTheVictim: Bool = true
    @Published var humanVictimDetails: String = ""
    @Published var reportDescription: String = ""
    @Published var imageSelection: PhotosPickerItem? = nil
    @Published var selectedImage: UIImage? = nil
    @Published var isPostingReport: Bool = false
    
    func postReport(location: Location, token: String) async throws {
        isPostingReport = true
        defer { isPostingReport = false }
        
        let imageUrl = await getImageUrl()
        let reportObject = makeReport(withImageUrl: imageUrl, location: location)
        let result = await AYServices.shared.postReportIncident(reportIncident: reportObject, token: token)
        
        try handlePostResult(result)
    }
    
    private func getImageUrl() async -> String? {
        guard let image = self.selectedImage else { return nil }
        do {
            return try await FirebaseService.shared.storeImageAndGetUrl(image)
        } catch {
            // TODO: Display Error
            return nil
        }
    }
    
    private func makeReport(withImageUrl imageUrl: String?, location: Location) -> ReportIncident {
        return ReportIncident(
            type: self.selectedReportType ?? .human,
            description: self.reportDescription,
            latitude: location.latitude,
            longitude: location.longitude,
            isUserTheVictim: self.selectedReportType == .human ? self.isUserTheVictim : nil,
            humanVictimDetails: self.humanVictimDetails.nonEmptyOrNil(),
            imageUrl: imageUrl
        )
    }
    
    private func handlePostResult(_ result: Result<SuccessMessageResponse, RequestError>) throws {
        switch result {
        case .success:
            print("✅ Report successfully posted!")
        case .failure:
            // TODO: Display Error
            throw PostReportIncidentError.genericError
        }
    }
    
    func isSubmitButtonEnabled() -> Bool {
        return !self.reportDescription.isEmpty && self.selectedReportType != nil
    }
    
    func removePhoto() {
        self.imageSelection = nil
        self.selectedImage = nil
    }
}
