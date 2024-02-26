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
                                    Button("Remove photo") {
                                        // remove photo
                                    }
                                    .foregroundStyle(.red)
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
                        try await editProfileVM.storeImage(forUser: LocalState.currentUserUid, token: token)
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
            .toolbar {
                if editProfileVM.isEditingProfile {
                    ToolbarItem {
                        ProgressView()
                    }
                } else if hasChangedProfile {
                    ToolbarItem {
                        Button("Confirm") {
                            Task {
                                let token = try await authVM.getFirebaseToken()
                                await editProfileVM.editProfile(token: token)
                            }
                        }
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
            Image(systemName: "person.fill")
                .font(.system(size: 40))
                .foregroundStyle(.white)
                .frame(width: 128, height: 128)
                .clipShape(Circle())
        }
    }
    
    //MARK: - Auxiliary Method
    
    private func updateUserData(with response: EditProfileResponse) {
        
    }
}

#Preview {
    EditProfileScreen()
        .environmentObject(AuthenticationViewModel())
}
