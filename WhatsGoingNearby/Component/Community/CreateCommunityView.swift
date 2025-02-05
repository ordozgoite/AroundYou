//
//  CreateCommunityView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 05/02/25.
//

import SwiftUI

struct CreateCommunityView: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @ObservedObject var communityVM: CommunityViewModel
    @Binding var isViewDisplayed: Bool
    
    var body: some View {
        NavigationStack {
            VStack {
                CommunityImage()
                
                Name()
                
                Spacer()
            }
            
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Cancel()
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Create()
                }
            }
        }
    }
    
    // MARK: - Image
    
    @ViewBuilder
    private func CommunityImage() -> some View {
        Image(systemName: "figure.2.circle.fill")
            .resizable()
            .foregroundStyle(.gray)
            .scaledToFit()
            .frame(width: 128, height: 128, alignment: .center)
    }
    
    // MARK: - Name
    
    @ViewBuilder
    private func Name() -> some View {
        TextField("Enter a Community Name", text: $communityVM.communityNameInput)
            .textFieldStyle(.plain)
            .multilineTextAlignment(.center)
            .font(.title)
    }
    
    // MARK: - Cancel
    
    @ViewBuilder
    private func Cancel() -> some View {
        Button("Cancel") {
            isViewDisplayed = false
        }
    }
    
    // MARK: - Create
    
    @ViewBuilder
    private func Create() -> some View {
        if communityVM.isCreatingCommunity {
            ProgressView()
        } else {
            Button("Create") {
                Task {
                    try await createCommunity()
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func createCommunity() async throws {
        let token = try await authVM.getFirebaseToken()
        // TODO: run PostCommunity request
    }
}

#Preview {
    CreateCommunityView(communityVM: CommunityViewModel(), isViewDisplayed: .constant(true))
}
