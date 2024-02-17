//
//  BugScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 17/02/24.
//

import SwiftUI

struct BugScreen: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var bugVM = BugViewModel()
    @Environment(\.presentationMode) var presentationMode
    @FocusState private var reportDescriptionIsFocused: Bool
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Text("Your feedback helps us improve the app experience for everyone.")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            
            TextField("Describe the bug you encountered...", text: $bugVM.descriptionTextInput, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(10...10)
                .focused($reportDescriptionIsFocused)
                .onChange(of: bugVM.descriptionTextInput) { newValue in
                    if newValue.count > bugVM.maxDescriptionLenght {
                        bugVM.descriptionTextInput = String(newValue.prefix(bugVM.maxDescriptionLenght))
                    }
                }
            
            HStack {
                Spacer()
                Text("\(bugVM.descriptionTextInput.count)/\(bugVM.maxDescriptionLenght)")
                    .foregroundStyle(.gray)
                    .font(.subheadline)
            }
            
            Spacer()
            
            if bugVM.isPostingReport {
                AYProgressButton(title: "Reporting...")
            } else {
                AYButton(title: "Report") {
                    Task {
                        reportDescriptionIsFocused = false
                        let token = try await authVM.getFirebaseToken()
                        await bugVM.postReport(token: token) {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
                .disabled(bugVM.descriptionTextInput.isEmpty)
            }
        }
        .padding()
        .navigationTitle("Report Bug")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    BugScreen()
        .environmentObject(AuthenticationViewModel())
}
