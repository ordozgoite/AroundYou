//
//  EditCommunityDescriptionView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 20/02/25.
//

import SwiftUI

struct EditCommunityDescriptionView: View {
    
    let communityId: String
    let previousDescription: String
    let updateCommunityDescription: (String) -> ()
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @ObservedObject var communityDetailVM: CommunityDetailViewModel
    @Binding var isViewDisplayed: Bool
    @FocusState private var isEditingDescription: Bool
    
    @State private var descriptionInput: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Add Community Description", text: $descriptionInput, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(10...10)
                        .focused($isEditingDescription)
                } footer: {
                    Text("The community description is visible to everyone who can see this community.")
                }
            }
            .onAppear {
                descriptionInput = previousDescription
                isEditingDescription = true
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Cancel()
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Save()
                }
            }
            .navigationTitle("Community Description")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Cancel
    
    @ViewBuilder
    private func Cancel() -> some View {
        Button("Cancel") {
            self.isViewDisplayed = false
        }
    }
    
    // MARK: - Save
    
    @ViewBuilder
    private func Save() -> some View {
        if communityDetailVM.isEditingDescription {
            ProgressView()
        } else {
            Button("Save") {
                Task {
                    try await saveDescription()
                }
            }
        }
    }
}

// MARK: - Private Methods

extension EditCommunityDescriptionView {
    private func saveDescription() async throws {
        do {
            try await updateDescription()
        } catch {
            print("❌ Error editing community description: \(error.localizedDescription)")
        }
    }
    
    private func updateDescription() async throws {
        try await postNewDescription()
        updateCommunityDescription(self.descriptionInput)
        self.isViewDisplayed = false
    }
    
    private func postNewDescription() async throws {
        let token = try await authVM.getFirebaseToken()
        try await communityDetailVM.editCommunityDescription(communityId: self.communityId, newDescription: self.descriptionInput.isEmpty ? nil : self.descriptionInput, token: token)
    }
}

#Preview {
    EditCommunityDescriptionView(communityId: UUID().uuidString, previousDescription: "Grupo exclusivo para membros dedicados de Catan dispostos a construir aldeias e cidades diariamente.", updateCommunityDescription: {_ in }, communityDetailVM: CommunityDetailViewModel(), isViewDisplayed: .constant(true))
        .environmentObject(AuthenticationViewModel())
}
