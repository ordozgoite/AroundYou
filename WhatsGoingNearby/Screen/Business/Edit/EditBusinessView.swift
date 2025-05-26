//
//  EditBusinessView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 26/05/25.
//

import SwiftUI

struct EditBusinessView: View {
    let business: FormattedBusinessShowcase
    
    private enum Field {
        case name
        case description
    }
    
    private let maxNameLenght = 30
    private let maxDescriptionLenght = 150
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var editBusinessVM = EditBusinessViewModel()
    @FocusState private var isEditingDescription: Bool
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Form {
                    BusinessImage()
                    
                    Name()
                    
                    Description()
                    
                    Category()
                    
                    Contact()
                    
                    LocationView()
                    
                    EditButton()
                }
                
                AYErrorAlert(message: editBusinessVM.overlayError.1 , isErrorAlertPresented: $editBusinessVM.overlayError.0)
            }
            .navigationTitle("Add Business")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                setCurrentValues()
            }
        }
    }
    
    // MARK: - Business Image
    
    @ViewBuilder
    private func BusinessImage() -> some View {
        Section {
            if let url = self.business.imageUrl {
                URLNotTapableImageView(imageURL: url)
                    .scaledToFill()
                    .frame(height: 200)
                    .listRowBackground(Color(.systemGroupedBackground))
            } else {
                VStack {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 24)
                }
                .foregroundStyle(.blue)
                .frame(height: 200)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        } footer: {
            Text("You can not edit your Business photo.")
        }
    }
    
    // MARK: - Name
    
    @ViewBuilder
    private func Name() -> some View {
        Section {
            TextField("Type your business' name", text: $editBusinessVM.nameInput)
                .onChange(of: editBusinessVM.nameInput) { newValue in
                    if newValue.count > maxNameLenght {
                        trimExcessChars(forField: .name, newValue: newValue)
                    }
                }
        } header: {
            Text("Name")
        } footer: {
            Text("\(editBusinessVM.nameInput.count)/\(maxNameLenght)")
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
    
    // MARK: - Description
    
    @ViewBuilder
    private func Description() -> some View {
        Section {
            TextField("Describe your business", text: $editBusinessVM.descriptionInput, axis: .vertical)
                .lineLimit(3...3)
                .focused($isEditingDescription)
                .onChange(of: editBusinessVM.descriptionInput) { newValue in
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
            Text("\(editBusinessVM.descriptionInput.count)/\(maxDescriptionLenght)")
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
                        editBusinessVM.selectedCategory = category
                    } label: {
                        Label(category.title, systemImage: category.iconName)
                        
                        if editBusinessVM.selectedCategory == category {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            } label: {
                HStack {
                    Text("Choose a Category")
                    Spacer()
                    Label(editBusinessVM.selectedCategory?.title ?? "", systemImage: editBusinessVM.selectedCategory?.iconName ?? "")
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
            
            TextField("Phone Number", text: $editBusinessVM.phoneNumber)
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
            
            TextField("WhatsApp Number", text: $editBusinessVM.whatsAppNumber)
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
            
            TextField("Instagram username", text: $editBusinessVM.instagramUsername)
                .textContentType(.username)
                .autocapitalization(.none)
                .onChange(of: editBusinessVM.instagramUsername) { newValue in
                    if newValue.hasPrefix("@") {
                        editBusinessVM.instagramUsername = String(newValue.dropFirst())
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
                Toggle(isOn: $editBusinessVM.isLocationVisible) {
                    Text("Display Precise Location")
                }
                
                MapView(latitude: self.business.latitude, longitude: self.business.longitude)
                        .frame(height: 256)
                        .opacity(editBusinessVM.isLocationVisible ? 1 : 0.5)
            }
        } header: {
            Text("Location")
        } footer: {
            Text("You can not edit your Business location.")
        }
    }
    
    // MARK: - Edit
    
    @ViewBuilder
    private func EditButton() -> some View {
        Section {
            ZStack {
                if editBusinessVM.isEditing {
                    AYProgressButton(title: "Editing...")
                } else {
                    AYButton(title: "Edit Business") {
                        Task {
                            try await handleBusinessEdit()
                        }
                    }
                    .disabled(!areInputsValid())
                }
            }
        }
        .listRowBackground(Color(.systemGroupedBackground))
    }
}

// MARK: - Private Methods

extension EditBusinessView {
    private func setCurrentValues() {
        editBusinessVM.descriptionInput = self.business.description ?? ""
        editBusinessVM.selectedCategory = self.business.category
        editBusinessVM.isLocationVisible = self.business.isLocationVisible
        editBusinessVM.nameInput = self.business.title
        editBusinessVM.instagramUsername = self.business.instagramUsername ?? ""
        editBusinessVM.whatsAppNumber = self.business.whatsAppNumber ?? ""
        editBusinessVM.phoneNumber = self.business.phoneNumber ?? ""
    }
    
    private func areInputsValid() -> Bool {
        return !(editBusinessVM.nameInput.isEmpty || editBusinessVM.selectedCategory == nil)
    }
    
    private func handleReturnKey(withNewValue newValue: String) {
        editBusinessVM.descriptionInput = newValue.replacingOccurrences(of: "\n", with: "")
        dismissKeyboard()
    }
    
    private func dismissKeyboard() {
        isEditingDescription = false
    }
    
    private func trimExcessChars(forField field: Field, newValue: String) {
        switch field {
        case .name:
            editBusinessVM.nameInput = String(newValue.prefix(maxNameLenght))
        case .description:
            editBusinessVM.descriptionInput = String(newValue.prefix(maxDescriptionLenght))
        }
    }
    
    private func handleBusinessEdit() async throws {
        do {
            try await attemptBusinessEdit()
        } catch {
            editBusinessVM.overlayError = (true, "Error trying to edit Business. Please try again.")
        }
    }
    
    private func attemptBusinessEdit() async throws {
        let token = try await authVM.getFirebaseToken()
        try await editBusinessVM.editBusiness(businessId: business.id, token: token)
        dismiss()
    }
}

//#Preview {
//    EditBusinessView()
//}
