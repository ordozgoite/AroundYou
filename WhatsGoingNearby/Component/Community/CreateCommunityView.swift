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
    @FocusState private var isDescriptionTextFieldFocused: Bool
    
    @Binding var isViewDisplayed: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                CommunityImage()
                
                Name()
                
                Divider()
                
                Description()
                
                Settings()
                
                Spacer()
                
                VStack {
                    Create()
                    
                    Disclaimer()
                }
            }
            .padding()
            .onReceive(locationManager.$location) { newLocation in
                if let newLocation = newLocation {
                    communityVM.latitude = newLocation.coordinate.latitude
                    communityVM.longitude = newLocation.coordinate.longitude
                }
            }
            .onAppear {
                communityVM.resetCreateCommunityInputs()
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
    
    // MARK: - Description
    
    @ViewBuilder
    private func Description() -> some View {
        VStack {
            HStack {
                Text("Description:")
                    .foregroundStyle(.gray)
                    .fontWeight(.bold)
                Spacer()
            }
            
            TextField("Briefly describe your Community...", text: $communityVM.communityDescriptionInput, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...3)
                .focused($isDescriptionTextFieldFocused)
                .onReceive(communityVM.communityDescriptionInput.publisher.last()) {
                    if ($0 as Character).asciiValue == 10 {
                        isDescriptionTextFieldFocused = false
                        communityVM.communityDescriptionInput.removeLast()
                    }
                }
        }
    }
    
    // MARK: - Settings
    
    @ViewBuilder
    private func Settings() -> some View {
        VStack {
            Duration()
            
            Divider()
            
            Location()
            
            Divider()
            
            Private()
        }
        .background(
            RoundedRectangle(cornerRadius: 16).fill(.thinMaterial)
        )
    }
    
    // MARK: - Duration
    
    @ViewBuilder
    private func Duration() -> some View {
        HStack {
            Text("Duration:")
                .fontWeight(.bold)
            
            Spacer()
            
            Menu {
                ForEach(CommunityDuration.allCases, id: \.self) { duration in
                    Button {
                        communityVM.selectedCommunityDuration = duration
                    } label: {
                        Text(duration.title)
                    }
                }
            } label: {
                HStack(spacing: 0) {
                    HStack {
                        Text(communityVM.selectedCommunityDuration.title)
                    }
                    .frame(width: 60)
                    Image(systemName: "chevron.up.chevron.down")
                        .scaleEffect(0.8)
                }
            }
        }
        .frame(height: 24)
        .foregroundStyle(.gray)
        .padding()
//        .background(
//            RoundedRectangle(cornerRadius: 16).fill(.thinMaterial)
//        )
    }
    
    // MARK: - Location
    
    @ViewBuilder
    private func Location() -> some View {
        HStack {
            Text("Display Location:")
                .fontWeight(.bold)
            
            Spacer()
            
            Toggle("", isOn: $communityVM.isLocationVisible)
        }
        .frame(height: 24)
        .foregroundStyle(.gray)
        .padding()
//        .background(
//            RoundedRectangle(cornerRadius: 16).fill(.thinMaterial)
//        )
    }
    
    // MARK: - Private
    
    @ViewBuilder
    private func Private() -> some View {
        HStack {
            Text("Ask to join:")
                .fontWeight(.bold)
            
            Spacer()
            
            Toggle("", isOn: $communityVM.isCommunityPrivate)
        }
        .frame(height: 24)
        .foregroundStyle(.gray)
        .padding()
//        .background(
//            RoundedRectangle(cornerRadius: 16).fill(.thinMaterial)
//        )
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
    
    // MARK: - Disclaimer
    
    @ViewBuilder
    private func Disclaimer() -> some View {
        Text("Only people within a 1 km radius of your community will be able to see and interact with it.")
            .multilineTextAlignment(.center)
            .foregroundStyle(.gray)
            .font(.caption)
    }
    
    // MARK: - Private Methods
    
    private func createCommunity() async throws {
        locationManager.requestLocation()
        if let location = locationManager.location {
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            
            let token = try await authVM.getFirebaseToken()
            await communityVM.posNewCommunity(latitude: latitude, longitude: longitude, token: token)
        } else {
            communityVM.overlayError = (true, ErrorMessage.locationDisabledErrorMessage)
        }
    }
}

#Preview {
    CreateCommunityView(
        communityVM: CommunityViewModel(),
        locationManager: LocationManager(),
        isViewDisplayed: .constant(true)
    )
}
