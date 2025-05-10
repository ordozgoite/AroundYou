//
//  ReportDetailViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 30/04/25.
//

import Foundation
import SwiftUI

@MainActor
class ReportDetailViewModel: ObservableObject {
    @Published var reportIncident: ReportIncident? = nil
    @Published var isLoading: Bool = false
    @Published var overlayError: (Bool, LocalizedStringKey) = (false, "")
    
    func getReport(withId reportId: String, token: String) async {
        isLoading = true
        defer { isLoading = false }
        let result = await AYServices.shared.getReport(reportId: reportId, token: token)
        handleGetReportResult(result)
    }
    
    private func handleGetReportResult(_ result: Result<ReportIncident, RequestError>) {
        switch result {
        case .success(let report):
            self.reportIncident = report
        case .failure:
            overlayError = (true, ErrorMessage.getReportInfoErrorMessage)
        }
    }
}
