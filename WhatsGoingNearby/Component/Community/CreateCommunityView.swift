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
    @ObservedObject var locationManager: LocationManager
    
    @Binding var isViewDisplayed: Bool
    
    @State private var latitude: Double = 0
    @State private var longitude: Double = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                CommunityImage()
                
                Name()
                
                Location()
                
                Spacer()
            }
            .padding(.top)
            .onReceive(locationManager.$location) { newLocation in
                if let newLocation = newLocation {
                    latitude = newLocation.coordinate.latitude
                    longitude = newLocation.coordinate.longitude
                }
            }
            
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Cancel()
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Create()
                }
            }
            .navigationTitle("New Community")
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
            .fontWeight(.bold)
    }
    
    // MARK: - Location
    
    @ViewBuilder
    private func Location() -> some View {
        Text("Your Community will be located on latitude \(latitude) and longitude \(longitude).")
            .multilineTextAlignment(.center)
            .foregroundStyle(.gray)
            .font(.caption)
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
    CreateCommunityView(
        communityVM: CommunityViewModel(),
        locationManager: LocationManager(),
        isViewDisplayed: .constant(true)
    )
}
