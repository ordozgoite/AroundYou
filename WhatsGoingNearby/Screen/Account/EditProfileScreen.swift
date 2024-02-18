//
//  EditProfileScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 17/02/24.
//

import SwiftUI

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
                Form {
                    
                    //MARK: - Profile Picture
                    
                    Section {
                        VStack(spacing: 16) {
                            HStack {
                                Spacer()
                                ProfilePicView(profilePic: authVM.profilePic, size: 128)
                                Spacer()
                            }
                            
                            Button("Edit photo") {
                                
                            }
                        }
                    }
                    .listRowBackground(Color(.systemGroupedBackground))
                    
                    //MARK: - Name and Bio
                    
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
            .onAppear {
                editProfileVM.nameInput = authVM.name
                if let bio = authVM.biography {
                    editProfileVM.bioInput = bio
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
                if editProfileVM.isLoading {
                    ToolbarItem {
                        ProgressView()
                    }
                } else if hasChangedProfile {
                    ToolbarItem {
                        Button("Confirm") {
                            Task {
                                let token = try await authVM.getFirebaseToken()
                                await editProfileVM.editProfile(token: token) { response in
                                    updateUserData(with: response)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func updateUserData(with response: EditProfileResponse) {
        authVM.name = response.name
        if let bio = response.biography {
            authVM.biography = bio
        }
    }
}

#Preview {
    EditProfileScreen()
        .environmentObject(AuthenticationViewModel())
}
