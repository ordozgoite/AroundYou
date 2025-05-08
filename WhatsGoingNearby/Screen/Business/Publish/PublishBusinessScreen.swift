//
//  AddBusinessView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 02/03/25.
//

import SwiftUI
import PhotosUI

struct PublishBusinessScreen: View {
    
    private enum Field {
        case name
        case description
    }
    
    private let maxNameLenght = 30
    private let maxDescriptionLenght = 150
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var publishBusinessVM = PublishBusinessViewModel()
    @ObservedObject var locationManager: LocationManager
    @FocusState private var isEditingDescription: Bool
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Form {
                    EditBusinessImage()
                    
                    Name()
                    
                    Description()
                    
                    Category()
                    
                    Contact()
                    
                    LocationView()
                    
                    Publish()
                }
                
                AYErrorAlert(message: publishBusinessVM.overlayError.1 , isErrorAlertPresented: $publishBusinessVM.overlayError.0)
            }
            .onChange(of: publishBusinessVM.imageSelection) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                        publishBusinessVM.image = image
                    }
                }
            }
            .navigationTitle("Add Business")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Edit Image
    
    @ViewBuilder
    private func EditBusinessImage() -> some View {
        ZStack(alignment: .topTrailing) {
            PhotosPicker(selection: $publishBusinessVM.imageSelection, matching: .images, preferredItemEncoding: .automatic) {
                BusinessImage()
            }
            
            if publishBusinessVM.image != nil {
                Button {
                    removePhoto()
                } label: {
                    RemoveMediaButton(size: .medium)
                }
            }
        }
    }
    
    // MARK: - Business Image
    
    @ViewBuilder
    private func BusinessImage() -> some View {
        Section {
            if let image = publishBusinessVM.image {
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
    }
    
    // MARK: - Name
    
    @ViewBuilder
    private func Name() -> some View {
        Section {
            TextField("Type your business' name", text: $publishBusinessVM.nameInput)
                .onChange(of: publishBusinessVM.nameInput) { newValue in
                    if newValue.count > maxNameLenght {
                        trimExcessChars(forField: .name, newValue: newValue)
                    }
                }
        } header: {
            Text("Name")
        } footer: {
            Text("\(publishBusinessVM.nameInput.count)/\(maxNameLenght)")
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
    
    // MARK: - Description
    
    @ViewBuilder
    private func Description() -> some View {
        Section {
            TextField("Describe your business", text: $publishBusinessVM.descriptionInput, axis: .vertical)
                .lineLimit(3...3)
                .focused($isEditingDescription)
                .onChange(of: publishBusinessVM.descriptionInput) { newValue in
                    if newValue.contains("\n") {
                        handleReturnKey(withNewValue: newValue)
                    }
                    
                    if newValue.count > maxDescriptionLenght {
                        trimExcessChars(forField: .description, newValue: newValue)
                    }
                }
        } header: {
            Text("Description")
        } footer: {
            Text("\(publishBusinessVM.descriptionInput.count)/\(maxDescriptionLenght)")
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
    
    // MARK: - Category
    
    @ViewBuilder
    private func Category() -> some View {
        Section("Category") {
            Menu {
                ForEach(BusinessCategory.allCases, id: \.self) { category in
                    Button {
                        publishBusinessVM.selectedCategory = category
                    } label: {
                        Label(category.title, systemImage: category.iconName)
                        
                        if publishBusinessVM.selectedCategory == category {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            } label: {
                HStack {
                    Text("Choose a Category")
                    Spacer()
                    Label(publishBusinessVM.selectedCategory?.title ?? "", systemImage: publishBusinessVM.selectedCategory?.iconName ?? "")
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    // MARK: - Contact
    
    @ViewBuilder
    private func Contact() -> some View {
        Section {
            VStack(spacing: 12) {
                AYPhoneNumberTextField(number: $publishBusinessVM.phoneNumber, placeholder: "Phone number")
                    .padding(.top)
                
                Divider()
                
                AYPhoneNumberTextField(number: $publishBusinessVM.whatsAppNumber, placeholder: "WhatsApp number")
                
                Divider()
                
                HStack {
                    Text("@")
                        .foregroundColor(.gray)
                    
                    TextField("Instagram username", text: $publishBusinessVM.instagramUsername)
                        .textContentType(.username)
                        .autocapitalization(.none)
                        .onChange(of: publishBusinessVM.instagramUsername) { newValue in
                            if newValue.hasPrefix("@") {
                                publishBusinessVM.instagramUsername = String(newValue.dropFirst())
                            }
                        }
                }
                .padding(.bottom)
            }
        } header: {
            Text("Contact")
        } footer: {
            Text("Let potential customers know how to reach you easily.")
        }
    }
    
    // MARK: - Location
    
    @ViewBuilder
    private func LocationView() -> some View {
        Section {
            VStack {
                Toggle(isOn: $publishBusinessVM.isLocationVisible) {
                    Text("Display Precise Location")
                }
                
                if let location = locationManager.location {
                    MapView(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                        .frame(height: 256)
                        .opacity(publishBusinessVM.isLocationVisible ? 1 : 0.5)
                }
            }
        } header: {
            Text("Location")
        } footer: {
            Text("Your location will be used to display your business to people nearby.")
        }
    }
    
    // MARK: - Publish
    
    @ViewBuilder
    private func Publish() -> some View {
        ZStack {
            if publishBusinessVM.isLoading {
                AYProgressButton(title: "Publishing...")
            } else {
                AYButton(title: "Publish") {
                    Task {
                        try await attemptBusinessPost()
                    }
                }
                .disabled(!areInputsValid())
            }
        }
        .listRowBackground(Color(.systemGroupedBackground))
    }
}

// MARK: - Private Methods

extension PublishBusinessScreen {
    private func areInputsValid() -> Bool {
        return !(publishBusinessVM.nameInput.isEmpty || publishBusinessVM.selectedCategory == nil)
    }
    
    private func handleReturnKey(withNewValue newValue: String) {
        publishBusinessVM.descriptionInput = newValue.replacingOccurrences(of: "\n", with: "")
        dismissKeyboard()
    }
    
    private func dismissKeyboard() {
        isEditingDescription = false
    }
    
    private func trimExcessChars(forField field: Field, newValue: String) {
        switch field {
        case .name:
            publishBusinessVM.nameInput = String(newValue.prefix(maxNameLenght))
        case .description:
            publishBusinessVM.descriptionInput = String(newValue.prefix(maxDescriptionLenght))
        }
    }
    
    private func attemptBusinessPost() async throws {
        do {
            try await postBusinessAndDismiss()
        } catch {
            publishBusinessVM.overlayError = (true, "Error trying to post Business.")
        }
    }
    
    private func postBusinessAndDismiss() async throws {
        try await postBusinessWithLocation()
        dismiss()
    }
    
    private func postBusinessWithLocation() async throws {
        locationManager.requestLocation()
        if let location = locationManager.location {
            let token = try await authVM.getFirebaseToken()
            
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            let currentLocation = Location(latitude: latitude, longitude: longitude)
            
            try await publishBusinessVM.publishBusiness(location: currentLocation, token: token)
        }
    }
    
    private func removePhoto() {
        publishBusinessVM.imageSelection = nil
        publishBusinessVM.image = nil
    }
}

#Preview {
    PublishBusinessScreen(locationManager: LocationManager())
        .environmentObject(AuthenticationViewModel())
}
