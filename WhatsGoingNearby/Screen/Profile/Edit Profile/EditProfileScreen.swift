//
//  EditProfileScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 17/02/24.
//

import SwiftUI
import PhotosUI

struct EditProfileScreen: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var editProfileVM = EditProfileViewModel()
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    
    private var hasChangedProfile: Bool {
        let usernameChanged = editProfileVM.usernameInput != authVM.username
        let nameChanged = editProfileVM.nameInput != authVM.name
        var bioChanged = editProfileVM.bioInput != authVM.biography
        if authVM.biography == nil && editProfileVM.bioInput.isEmpty { bioChanged = false }
        
        return usernameChanged || nameChanged || bioChanged
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    if editProfileVM.isLoading {
                        ProgressView()
                    } else {
                        Form {
                            Photo()
                            
                            RemovePhotoButton()
                            
                            EditPhoto()
                            
                            Username()
                            
                            FullName()
                            
                            Biography()
                        }
                    }
                }
                
                AYErrorAlert(message: editProfileVM.overlayError.1, isErrorAlertPresented: $editProfileVM.overlayError.0)
            }
            .onAppear {
                getUserInfo()
            }
            .onChange(of: editProfileVM.imageSelection) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                        displayCropView(withImage: image)
                    }
                }
            }
            .alert(isPresented: $editProfileVM.isSuccessAlertDisplayed) {
                Alert(
                    title: Text("Done"),
                    message: Text("Your profile was successfully updated.")
                )
            }
            .navigationTitle("Edit profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Confirm()
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Dismiss()
                }
            }
        }
    }
    
    // MARK: - Photo
    
    @ViewBuilder
    private func Photo() -> some View {
        Section {
            HStack {
                Spacer()
                ProfileImage()
                Spacer()
            }
        }
        .listRowBackground(Color(.systemGroupedBackground))
    }
    
    //MARK: - Profile Image
    
    @ViewBuilder
    private func ProfileImage() -> some View {
        if editProfileVM.isStoringPhoto {
            ProgressView()
        } else if let url = editProfileVM.profilePicUrl {
            URLTapableImageView(imageURL: url)
                .aspectRatio(contentMode: .fill)
                .frame(width: 128, height: 128)
                .clipShape(Circle())
        } else {
            Image(systemName: "person.circle.fill")
                .resizable()
                .foregroundStyle(.gray)
                .frame(width: 128, height: 128)
                .clipShape(Circle())
        }
    }
    
    // MARK: - Remove Photo
    
    @ViewBuilder
    private func RemovePhotoButton() -> some View {
        if editProfileVM.profilePicUrl != nil {
            Section {
                HStack {
                    Spacer()
                    if editProfileVM.isRemovingPhoto {
                        Text("Removing photo...")
                            .foregroundStyle(.gray)
                    } else {
                        Button("Remove photo") {
                            Task {
                                let token = try await authVM.getFirebaseToken()
                                await editProfileVM.removePhoto(token: token)
                                authVM.profilePic = nil
                            }
                        }
                        .foregroundStyle(.red)
                    }
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Edit Photo
    
    @ViewBuilder
    private func EditPhoto() -> some View {
        Section {
            if editProfileVM.isStoringPhoto {
                HStack {
                    Spacer()
                    Text("Updating photo...")
                        .foregroundStyle(.gray)
                    Spacer()
                }
            } else {
                HStack {
                    Spacer()
                    PhotosPicker(selection: $editProfileVM.imageSelection, matching: .images, preferredItemEncoding: .automatic) {
                        Text("Edit photo")
                            .foregroundStyle(.blue)
                    }
                    Spacer()
                }
                .fullScreenCover(isPresented: $editProfileVM.isCropViewDisplayed) {
                    editProfileVM.selectedImage = nil
                } content: {
                    CropScreen(size: CGSize(width: 300, height: 300), image: editProfileVM.selectedImage) { croppedImage, status in
                        if let croppedImage {
                            editProfileVM.croppedImage = croppedImage
                            handleImageUpdate()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Username
    
    @ViewBuilder
    private func Username() -> some View {
        Section {
            HStack {
                Text("Username")
                    .frame(width: 80)
                
                TextField("Username", text: $editProfileVM.usernameInput)
                    .textInputAutocapitalization(.never)
                    .onChange(of: editProfileVM.usernameInput) { newValue in
                        trimUsername(withNewValue: newValue)
                    }
            }
        } footer: {
            Text("Your username needs to be unique. This is the main way other users will see you on the app.")
        }
    }
    
    // MARK: - Full name
    
    @ViewBuilder
    private func FullName() -> some View {
        Section {
            HStack {
                Text("Name")
                    .frame(width: 80)
                
                TextField("Full name (optional)", text: $editProfileVM.nameInput)
                    .textInputAutocapitalization(.words)
                    .onChange(of: editProfileVM.nameInput) { newValue in
                        trimName(withNewValue: newValue)
                    }
            }
        } footer: {
            Text("Your full name will be displayed on your profile.")
        }
    }
    
    // MARK: - Biography
    
    @ViewBuilder
    private func Biography() -> some View {
        Section {
            HStack(alignment: .top) {
                Text("Biography")
                    .frame(width: 80)
                
                TextField("Biography", text: $editProfileVM.bioInput, axis: .vertical)
                    .onChange(of: editProfileVM.bioInput) { newValue in
                        trimBio(withNewValue: newValue)
                    }
            }
        } footer: {
            Text("Your biography will be displayed on your profile. Write anything you want to share about yourself.")
        }
        .alert(isPresented: $editProfileVM.isChangeAlertDisplayed) {
            Alert(
                title: Text("Discard changes?"),
                message: Text("If you quit this screen, you will lose your changes."),
                primaryButton: .destructive(Text("Discard")) {
                    presentationMode.wrappedValue.dismiss()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    // MARK: - Confirm
    
    @ViewBuilder
    private func Confirm() -> some View {
        if editProfileVM.isEditingProfile {
            ProgressView()
        } else if hasChangedProfile {
            Button("Confirm") {
                editProfile()
            }
        }
    }
    
    // MARK: - Dismiss
    
    @ViewBuilder
    private func Dismiss() -> some View {
        Button {
            if hasChangedProfile {
                editProfileVM.isChangeAlertDisplayed = true
            } else {
                presentationMode.wrappedValue.dismiss()
            }
        } label: {
            Image(systemName: "xmark")
                .foregroundStyle(.gray)
        }
    }
}

// MARK: - Private Methods

extension EditProfileScreen {
    private func getUserInfo() {
        Task {
            let token = try await authVM.getFirebaseToken()
            await editProfileVM.getUserInfo(token: token)
        }
    }
    
    private func displayCropView(withImage image: UIImage) {
        editProfileVM.selectedImage = image
        editProfileVM.isCropViewDisplayed = true
    }
    
    private func handleImageUpdate() {
        Task {
            let token = try await authVM.getFirebaseToken()
            if let url = try await editProfileVM.storeImageAndGetUrl(forUser: LocalState.currentUserUid, token: token) {
                authVM.profilePic = url
            }
        }
    }
    
    private func trimUsername(withNewValue newValue: String) {
        if newValue.count > Constants.MAX_USERNAME_LENGHT {
            editProfileVM.usernameInput = String(newValue.prefix(Constants.MAX_USERNAME_LENGHT))
        }
    }
    
    private func trimName(withNewValue newValue: String) {
        if newValue.count > Constants.MAX_NAME_LENGHT {
            editProfileVM.nameInput = String(newValue.prefix(Constants.MAX_NAME_LENGHT))
        }
    }
    
    private func trimBio(withNewValue newValue: String) {
        if newValue.count > Constants.MAX_BIO_LENGHT {
            editProfileVM.bioInput = String(newValue.prefix(Constants.MAX_BIO_LENGHT))
        }
    }
    
    private func editProfile() {
        hideKeyboard()
        Task {
            let username = editProfileVM.usernameInput
            let name = editProfileVM.nameInput
            let bio = editProfileVM.bioInput
            
            let token = try await authVM.getFirebaseToken()
            if await editProfileVM.editProfile(token: token) {
                authVM.username = username
                if !name.isEmpty { authVM.name = name }
                if !bio.isEmpty { authVM.biography = bio }
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    EditProfileScreen()
        .environmentObject(AuthenticationViewModel())
}
