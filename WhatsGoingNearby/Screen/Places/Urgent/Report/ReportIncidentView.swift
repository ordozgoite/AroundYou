//
//  ReportView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 25/03/25.
//

import SwiftUI
import PhotosUI

struct ReportIncidentView: View {
    @Binding var isViewDisplayed: Bool
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var vm = ReportIncidentViewModel()
    @ObservedObject var locationManager: LocationManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Type()
                
                if vm.selectedReportType != nil {
                    Description()
                    
                    Picture()
                }
            }
            .onChange(of: vm.imageSelection) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                        vm.selectedImage = image
                    }
                }
            }
            .navigationTitle("Report an Incident")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Cancel()
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Post()
                }
            }
        }
    }
    
    // MARK: - Type
    
    @ViewBuilder
    private func Type() -> some View {
        Section("Report Type") {
            Menu {
                ForEach(IncidentType.allCases, id: \.self) { type in
                    Button {
                        vm.selectedReportType = type
                    } label: {
                        Label(type.title, systemImage: type.iconName)
                        
                        if vm.selectedReportType == type {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            } label: {
                HStack {
                    Text("What are you reporting?")
                    Spacer()
                    Label(vm.selectedReportType?.title ?? "", systemImage: vm.selectedReportType?.iconName ?? "")
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    // MARK: - Description
    
    @ViewBuilder
    private func Description() -> some View {
        Section("Description") {
            if vm.selectedReportType == .human {
                Toggle("Are you the victim?", isOn: $vm.isUserTheVictim)
                
                if !vm.isUserTheVictim {
                    TextField("Describe the victim (optional)", text: $vm.humanVictimDetails)
                }
            }
            
            TextField("Describe the incident", text: $vm.reportDescription)
        }
    }
    
    // MARK: - Picture
    
    @ViewBuilder
    private func Picture() -> some View {
        Section(header: Text("Add a Picture (Optional)")) {
            ZStack(alignment: .topTrailing) {
                PhotosPicker(selection: $vm.imageSelection, matching: .images) {
                    ReportImage()
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
    
    // MARK: - Report Image
    
    @ViewBuilder
    private func ReportImage() -> some View {
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
    
    // MARK: - Cancel
    
    @ViewBuilder
    private func Cancel() -> some View {
        Button("Cancel") {
            self.isViewDisplayed = false
        }
    }
    
    // MARK: - Post
    
    @ViewBuilder
    private func Post() -> some View {
        if vm.isPostingReport {
            ProgressView()
        } else {
            Button("Post") {
                attemptReportPost()
            }
            .disabled(!vm.isSubmitButtonEnabled())
        }
    }
}

// MARK: - Private Methods

extension ReportIncidentView {
    private func attemptReportPost() {
        Task {
            do {
                try await handleReportPost()
            } catch {
                print("❌ Error posting report: \(error)")
            }
        }
    }
    
    private func handleReportPost() async throws {
        let currentLocation = try getCurrentLocation()
        let token = try await authVM.getFirebaseToken()
        try await vm.postReport(location: currentLocation, token: token)
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
}

#Preview {
    ReportIncidentView(isViewDisplayed: .constant(true), locationManager: LocationManager())
}
