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
                
                Divider()
                
                Duration()
                
                Location()
                
                Spacer()
                
                Create()
            }
            .padding()
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
    
    // MARK: - Duration
    
    @ViewBuilder
    private func Duration() -> some View {
        VStack {
            HStack {
                Text("Duration:")
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("4 hours")
            }
            .foregroundStyle(.gray)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16).fill(.thinMaterial)
            )
            
//            Text("Communities stay active and visible for only 4 hours after its creation.")
//                .multilineTextAlignment(.center)
//                .foregroundStyle(.gray)
//                .font(.caption)
        }
    }
    
    // MARK: - Location
    
    @ViewBuilder
    private func Location() -> some View {
        VStack {
            HStack {
                Text("Location:")
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("\(latitude), \(longitude)")
            }
            .foregroundStyle(.gray)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16).fill(.thinMaterial)
            )
            
//            Text("Only people within a 1 km radius of your community will be able to see and interact with it.")
//                .multilineTextAlignment(.center)
//                .foregroundStyle(.gray)
//                .font(.caption)
        }
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
            AYProgressButton(title: "Creating...")
        } else {
            AYButton(title: "Create Community") {
                Task {
                    try await createCommunity()
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func createCommunity() async throws {
        communityVM.isCreatingCommunity = true
        
//        let token = try await authVM.getFirebaseToken()
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
