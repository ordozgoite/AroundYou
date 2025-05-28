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
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var navCoordinator: NavigationCoordinator
    @StateObject private var publishBusinessVM = PublishBusinessViewModel()
    @FocusState private var isEditingDescription: Bool
    
    var body: some View {
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
        .navigationTitle("Add Business")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Edit Image
    
    @ViewBuilder
    private func EditBusinessImage() -> some View {
        ZStack(alignment: .topTrailing) {
            Menu {
                Button {
                    publishBusinessVM.isCameraPickerDisplayed = true
                } label: {
                    Label("Camera", systemImage: "camera")
                }
                
                Button {
                    publishBusinessVM.isPhotoPickerDisplayed = true
                } label: {
                    Label("Photos", systemImage: "photo")
                }
            } label: {
                BusinessImage()
            }
            .fullScreenCover(isPresented: $publishBusinessVM.isCameraPickerDisplayed) {
                CameraView { image in
                    publishBusinessVM.image = image
                }
            }
            .sheet(isPresented: $publishBusinessVM.isPhotoPickerDisplayed) {
                PhotoPicker(selectedPhoto: $publishBusinessVM.image)
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
                PhoneNumber()
                
                Divider()
                
                WhatsApp()
                
                Divider()
                
                Instagram()
            }
        } header: {
            Text("Contact")
        } footer: {
            Text("Let potential customers know how to reach you easily.")
        }
    }
    
    // MARK: - Phone Number
    
    @ViewBuilder
    private func PhoneNumber() -> some View {
        HStack {
            Image(systemName: "phone.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24, alignment: .center)
            
            TextField("Phone Number", text: $publishBusinessVM.phoneNumber)
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
                .autocapitalization(.none)
        }
        .padding(.top)
    }
    
    // MARK: - WhatsApp
    
    @ViewBuilder
    private func WhatsApp() -> some View {
        HStack {
            Image(Constants.whatsAppLogoImageName)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24, alignment: .center)
            
            TextField("WhatsApp Number", text: $publishBusinessVM.whatsAppNumber)
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
                .autocapitalization(.none)
        }
    }
    
    // MARK: - Instagram
    
    @ViewBuilder
    private func Instagram() -> some View {
        HStack {
            Image(Constants.instagramLogoImageName)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24, alignment: .center)
            
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
        Section {
            VStack {
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
                
                Disclaimer()
            }
        }
        .listRowBackground(Color(.systemGroupedBackground))
    }
    
    // MARK: - Disclaimer
    
    @ViewBuilder
    private func Disclaimer() -> some View {
        AYDisclaimerView(text: "Your Business will be available for **15 days**.")
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
        navCoordinator.goBack()
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
        publishBusinessVM.image = nil
    }
}

#Preview {
    PublishBusinessScreen()
        .environmentObject(AuthenticationViewModel())
}
