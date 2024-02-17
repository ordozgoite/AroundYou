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
}

struct ReportScreen: View {
    
    let reportedUserUid: String
    let publicationId: String?
    let commentId: String?
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var reportVM = ReportViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
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
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ReportScreen(reportedUserUid: "", publicationId: "", commentId: "")
}
