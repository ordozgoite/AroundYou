//
//  ReportScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 16/02/24.
//

import SwiftUI

enum ReportTarget {
    case user
    case publication
    case comment
    case business
}

struct ReportScreen: View {
    
    let reportedUserUid: String
    let publicationId: String?
    let commentId: String?
    let businessId: String?
    
    init(reportedUserUid: String, publicationId: String? = nil, commentId: String? = nil, businessId: String? = nil) {
        self.reportedUserUid = reportedUserUid
        self.publicationId = publicationId
        self.commentId = commentId
        self.businessId = businessId
    }
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var reportVM = ReportViewModel()
    @Environment(\.presentationMode) var presentationMode
    @FocusState private var reportDescriptionIsFocused: Bool
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Text("What type of issue are you reporting?")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
                
                Spacer()
                
                TextField("Describe what happened...", text: $reportVM.descriptionTextInput, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(10...10)
                    .focused($reportDescriptionIsFocused)
                    .onChange(of: reportVM.descriptionTextInput) { newValue in
                        if newValue.count > reportVM.maxDescriptionLenght {
                            reportVM.descriptionTextInput = String(newValue.prefix(reportVM.maxDescriptionLenght))
                        }
                    }
                
                HStack {
                    Spacer()
                    Text("\(reportVM.descriptionTextInput.count)/\(reportVM.maxDescriptionLenght)")
                        .foregroundStyle(.gray)
                        .font(.subheadline)
                }
                
                Spacer()
                
                if reportVM.isPostingReport {
                    AYProgressButton(title: "Reporting...")
                } else {
                    AYButton(title: "Report") {
                        Task {
                            reportDescriptionIsFocused = false
                            let token = try await authVM.getFirebaseToken()
                            var reportDescription: String?
                            if !reportVM.descriptionTextInput.isEmpty { reportDescription = reportVM.descriptionTextInput  }
                            await reportVM.postReport(reportedUserUid: reportedUserUid, publicationId: publicationId, commentId: commentId, reportDescription: reportDescription, token: token) {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }
                }
            }
            .padding()
            
            AYErrorAlert(message: reportVM.overlayError.1, isErrorAlertPresented: $reportVM.overlayError.0)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ReportScreen(reportedUserUid: "", publicationId: nil, commentId: nil, businessId: nil)
        .environmentObject(AuthenticationViewModel())
}
