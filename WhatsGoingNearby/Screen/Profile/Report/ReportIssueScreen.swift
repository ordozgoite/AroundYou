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

struct ReportIssueScreen: View {
    
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
    @StateObject private var vm = ReportIssueViewModel()
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
                
                TextField("Describe what happened...", text: $vm.descriptionTextInput, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(10...10)
                    .focused($reportDescriptionIsFocused)
                    .onChange(of: vm.descriptionTextInput) { newValue in
                        if newValue.count > vm.maxDescriptionLenght {
                            vm.descriptionTextInput = String(newValue.prefix(vm.maxDescriptionLenght))
                        }
                    }
                
                HStack {
                    Spacer()
                    Text("\(vm.descriptionTextInput.count)/\(vm.maxDescriptionLenght)")
                        .foregroundStyle(.gray)
                        .font(.subheadline)
                }
                
                Spacer()
                
                if vm.isPostingReport {
                    AYProgressButton(title: "Reporting...")
                } else {
                    AYButton(title: "Report") {
                        Task {
                            reportDescriptionIsFocused = false
                            let token = try await authVM.getFirebaseToken()
                            var reportDescription: String?
                            if !vm.descriptionTextInput.isEmpty { reportDescription = vm.descriptionTextInput  }
                            await vm.postReport(reportedUserUid: reportedUserUid, publicationId: publicationId, commentId: commentId, reportDescription: reportDescription, token: token) {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }
                }
            }
            .padding()
            
            AYErrorAlert(message: vm.overlayError.1, isErrorAlertPresented: $vm.overlayError.0)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ReportIssueScreen(reportedUserUid: "", publicationId: nil, commentId: nil, businessId: nil)
        .environmentObject(AuthenticationViewModel())
}
