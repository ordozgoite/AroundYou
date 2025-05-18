//
//  LostAndFoundView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 24/03/25.
//

import SwiftUI
import PhotosUI

struct LostAndFoundView: View {
    @Binding var isViewDisplayed: Bool
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var vm = LostAndFoundViewModel()
    @ObservedObject var locationManager: LocationManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Form {
                    Description()
                    
                    Picture()
                    
                    LocationAndDate()
                    
                    Reward()
                }
                
                AYErrorAlert(message: vm.overlayError.1 , isErrorAlertPresented: $vm.overlayError.0)
            }
            .onChange(of: vm.imageSelection) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                        vm.selectedImage = image
                    }
                }
            }
            .navigationBarTitle("Lost & Found")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Cancel()
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Submit()
                }
            }
        }
    }
    
    // MARK: - Description
    
    @ViewBuilder
    private func Description() -> some View {
        Section("Lost Item Information") {
            TextField("What did you lose?", text: $vm.itemName)
                .textFieldStyle(.plain)
            
            TextField("Item description (optional)", text: $vm.itemDescription)
            .textFieldStyle(.plain)        }
    }
    
    // MARK: - Picture
    
    @ViewBuilder
    private func Picture() -> some View {
        Section(header: Text("Add a Picture (Optional)")) {
            ZStack(alignment: .topTrailing) {
                PhotosPicker(selection: $vm.imageSelection, matching: .images) {
                    ItemImage()
                }
                
                if vm.selectedImage != nil {
                    Button {
                        vm.removePhoto()
                    } label: {
                        RemoveMediaButton(size: .medium)
                    }
                }
            }
        }
    }
    
    // MARK: - Item Image
    
    @ViewBuilder
    private func ItemImage() -> some View {
        if let image = vm.selectedImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 200)
                .listRowBackground(Color(.systemGroupedBackground))
        } else {
            VStack {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 24)
                
                Text("Add Photo")
                    .bold()
            }
            .foregroundStyle(.blue)
            .frame(height: 200)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
    
    // MARK: - Location & Date
    
    @ViewBuilder
    private func LocationAndDate() -> some View {
        Section {
            TextField("Describe the location (optional)", text: $vm.lostLocationDescription)
                .textFieldStyle(.plain)
            
            NavigationLink {
                LostItemMapView(selectedCoordinate: $vm.lostItemCoordinate)
            } label: {
                Label(
                    vm.lostItemCoordinate == nil ? "Choose location" : "\(vm.lostItemCoordinate!.latitude), \(vm.lostItemCoordinate!.longitude)",
                    systemImage: "mappin"
                )
                .foregroundStyle(.blue)
            }
            
            
            DatePicker("Date and time", selection: $vm.lostDate, displayedComponents: [.date, .hourAndMinute])
        } header: {
            Text("Location and Date")
        } footer: {
            Text("Provide the approximate location and time when you lost the item to help with the search.")
        }
    }
    
    // MARK: - Reward
    
    @ViewBuilder
    private func Reward() -> some View {
        Section {
            Toggle("Offer a reward?", isOn: $vm.rewardOffer)
                .toggleStyle(SwitchToggleStyle())
        } header: {
            Text("Reward")
        } footer: {
            Text("You can offer a reward to encourage people to return your item.")
        }
    }
    
    // MARK: - Cancel
    
    @ViewBuilder
    private func Cancel() -> some View {
        Button("Cancel") {
            self.isViewDisplayed = false
        }
    }
    
    // MARK: - Submit
    
    @ViewBuilder
    private func Submit() -> some View {
        if vm.isPostingItem {
            ProgressView()
        } else {
            Button("Submit") {
                attemptPostItem()
            }
            .disabled(!vm.isSubmitButtonEnabled())
        }
    }
}

// MARK: - Private Methods

extension LostAndFoundView {
    private func attemptPostItem() {
        Task {
            do {
                try await handlePostItem()
            } catch {
                print("❌ Error posting item: \(error)")
            }
        }
    }
    
    private func handlePostItem() async throws {
        let currentLocation = try getCurrentLocation()
        let token = try await authVM.getFirebaseToken()
        try await vm.postLostItem(location: currentLocation, token: token)
        notifyLocationSensitiveDataRefresh()
        dismiss()
    }
    
    private func getCurrentLocation() throws -> Location {
        locationManager.requestLocation()
        if let location = locationManager.location {
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            return Location(latitude: latitude, longitude: longitude)
        } else {
            throw LocationError.unableToGetCurrentLocation
        }
    }
    
    private func notifyLocationSensitiveDataRefresh() {
        NotificationCenter.default.post(name: .refreshLocationSensitiveData, object: nil)
    }
}

#Preview {
    LostAndFoundView(isViewDisplayed: .constant(true), locationManager: LocationManager())
}
