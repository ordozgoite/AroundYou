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
                            
                            //MARK: - Profile Photo
                            
                            Section {
                                HStack {
                                    Spacer()
                                    ProfileImage()
                                    Spacer()
                                }
                            }
                            .listRowBackground(Color(.systemGroupedBackground))
                            
                            //MARK: - Remove Photo
                            
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
                            
                            //MARK: - Edit Photo
                            
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
                                                Task {
                                                    let token = try await authVM.getFirebaseToken()
                                                    if let url = try await editProfileVM.storeImage(forUser: LocalState.currentUserUid, token: token) {
                                                        authVM.profilePic = url
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            
                            //MARK: - Edit Info
                            
                            Section {
                                VStack {
                                    HStack {
                                        Text("Username")
                                            .frame(width: 80)
                                        
                                        TextField("Username", text: $editProfileVM.usernameInput)
                                            .textInputAutocapitalization(.never)
                                            .onChange(of: editProfileVM.usernameInput) { newValue in
                                                if newValue.count > editProfileVM.maxUsernameLenght {
                                                    editProfileVM.usernameInput = String(newValue.prefix(editProfileVM.maxUsernameLenght))
                                                }
                                            }
                                    }
                                    
                                    Divider()
                                        .padding(.leading, 80)
                                    
                                    HStack {
                                        Text("Full name")
                                            .frame(width: 80)
                                        
                                        TextField("Full name", text: $editProfileVM.nameInput)
                                            .textInputAutocapitalization(.words)
                                            .onChange(of: editProfileVM.nameInput) { newValue in
                                                if newValue.count > editProfileVM.maxNameLenght {
                                                    editProfileVM.nameInput = String(newValue.prefix(editProfileVM.maxNameLenght))
                                                }
                                            }
                                    }
                                    
                                    Divider()
                                        .padding(.leading, 80)
                                    
                                    HStack(alignment: .top) {
                                        Text("Biography")
                                            .frame(width: 80)
                                        
                                        TextField("Biography", text: $editProfileVM.bioInput, axis: .vertical)
                                            .onChange(of: editProfileVM.bioInput) { newValue in
                                                if newValue.count > editProfileVM.maxBioLenght {
                                                    editProfileVM.bioInput = String(newValue.prefix(editProfileVM.maxBioLenght))
                                                }
                                            }
                                    }
                                }
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
                    }
                }
                
                AYErrorAlert(message: editProfileVM.overlayError.1, isErrorAlertPresented: $editProfileVM.overlayError.0)
            }
            .onAppear {
                Task {
                    let token = try await authVM.getFirebaseToken()
                    await editProfileVM.getUserInfo(token: token)
                }
            }
            .onChange(of: editProfileVM.imageSelection) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                        editProfileVM.selectedImage = image
                        editProfileVM.isCropViewDisplayed = true
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
                if editProfileVM.isEditingProfile {
                    ToolbarItem {
                        ProgressView()
                    }
                } else if hasChangedProfile {
                    ToolbarItem {
                        Button("Confirm") {
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
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
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
        }
    }
    
    //MARK: - Profile Image
    
    @ViewBuilder
    private func ProfileImage() -> some View {
        if editProfileVM.isStoringPhoto {
            ProgressView()
        } else if let url = editProfileVM.profilePicUrl {
            URLImageView(imageURL: url)
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
}

#Preview {
    EditProfileScreen()
        .environmentObject(AuthenticationViewModel())
}
