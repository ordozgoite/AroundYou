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
                        let token = try await authVM.getFirebaseToken()
                        await bugVM.postReport(token: token) {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
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
