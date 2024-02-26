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
        let nameChanged = editProfileVM.nameInput != authVM.name
        var bioChanged = editProfileVM.bioInput != authVM.biography
        if authVM.biography == nil && editProfileVM.bioInput.isEmpty { bioChanged = false }
        
        return nameChanged || bioChanged
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if editProfileVM.isLoading {
                    ProgressView()
                } else {
                    Form {
                        Section {
                            HStack {
                                Spacer()
                                ProfileImage()
                                Spacer()
                            }
                        }
                        .listRowBackground(Color(.systemGroupedBackground))
                        
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
                            }
                        }
                        
                        Section {
                            VStack {
                                HStack {
                                    Text("Name")
                                        .frame(width: 80)
                                    
                                    TextField("Name", text: $editProfileVM.nameInput)
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
            .onAppear {
                Task {
                    let token = try await authVM.getFirebaseToken()
                    await editProfileVM.getUserInfo(token: token)
                }
            }
            .onChange(of: editProfileVM.imageSelection) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        editProfileVM.imageData = data
                        let token = try await authVM.getFirebaseToken()
                        if let url = try await editProfileVM.storeImage(forUser: LocalState.currentUserUid, token: token) {
                            authVM.profilePic = url
                        }
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
                                let name = editProfileVM.nameInput
                                let bio = editProfileVM.bioInput
                                
                                let token = try await authVM.getFirebaseToken()
                                await editProfileVM.editProfile(token: token)
                                
                                if !name.isEmpty { authVM.name = name }
                                if !bio.isEmpty { authVM.biography = bio }
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
