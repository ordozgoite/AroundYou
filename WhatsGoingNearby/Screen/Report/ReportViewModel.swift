//
//  ReportViewModel.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 17/02/24.
//

import Foundation

@MainActor
class ReportViewModel: ObservableObject {
    
    let maxDescriptionLenght = 500
    @Published var descriptionTextInput: String = ""
    @Published var isPostingReport: Bool = false
    @Published var overlayError: (Bool, String) = (false, "")
    
    func postReport(reportedUserUid: String, publicationId: String?, commentId: String?, reportDescription: String?, token: String, dismissScreen: () -> ()) async {
        isPostingReport = true
        let response = await AYServices.shared.postNewReport(report: ReportDTO(reportedUserUid: reportedUserUid, publicationId: publicationId, commentId: commentId, reportDescription: reportDescription), token: token)
        isPostingReport = false
        
        switch response {
        case .success:
            dismissScreen()
        case .failure(let failure):
            overlayError = (true, ErrorMessage.defaultErrorMessage)
        }
    }
}
