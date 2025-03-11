//
//  AddBusinessView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 02/03/25.
//

import SwiftUI

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
            Form {
                ImageView()
                
                Name()
                
                Description()
                
                Category()
                
                Contact()
            }
            .navigationTitle("Add Business")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Publish()
                }
            }
        }
    }
    
    // MARK: - Image
    
    @ViewBuilder
    private func ImageView() -> some View {
        Section {
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
            VStack {
                TextField("Phone number", text: $publishBusinessVM.phoneNumber)
                TextField("WhatsApp number", text: $publishBusinessVM.whatsAppNumber)
                TextField("Instagram username", text: $publishBusinessVM.instagramUsername)
            }
        } header: {
            Text("Contact")
        } footer: {
            Text("You can")
        }

    }
    
    // MARK: - Publish
    
    @ViewBuilder
    private func Publish() -> some View {
        if publishBusinessVM.isLoading {
            ProgressView()
        } else {
            Button("Publish") {
                Task {
                    try await attemptBusinessPost()
                }
            }
            .disabled(!areInputsValid())
        }
    }
}

// MARK: - Private Methods

extension PublishBusinessScreen {
    private func areInputsValid() -> Bool {
        return !(publishBusinessVM.nameInput.isEmpty || publishBusinessVM.descriptionInput.isEmpty || publishBusinessVM.selectedCategory == nil)
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
}

#Preview {
    PublishBusinessScreen(locationManager: LocationManager())
        .environmentObject(AuthenticationViewModel())
}
