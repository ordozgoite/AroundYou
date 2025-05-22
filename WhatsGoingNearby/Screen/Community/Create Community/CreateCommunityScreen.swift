//
//  CreateCommunityView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 05/02/25.
//

import SwiftUI
import PhotosUI

struct CreateCommunityScreen: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var createCommunityVM = CreateCommunityViewModel()
    @ObservedObject var communityVM: CommunityViewModel
    @ObservedObject var locationManager: LocationManager
    @FocusState private var isDescriptionTextFieldFocused: Bool
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 16) {
                    EditCommunityImage()
                    
                    Name()
                    
                    Divider()
                    
                    Description()
                    
                    Settings()
                    
                    Spacer()
                    
                    VStack {
                        Create()
                        
                        Disclaimer()
                    }
                }
                
                AYErrorAlert(message: createCommunityVM.overlayError.1 , isErrorAlertPresented: $createCommunityVM.overlayError.0)
            }
            .padding()
            .onAppear {
                createCommunityVM.resetCreateCommunityInputs()
            }
            .onChange(of: createCommunityVM.imageSelection) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                        createCommunityVM.image = image
                        createCommunityVM.isCropViewDisplayed = true
                    }
                }
            }
            .navigationTitle("New Community")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Image
    
    @ViewBuilder
    private func EditCommunityImage() -> some View {
        ZStack(alignment: .topTrailing) {
            PhotosPicker(selection: $createCommunityVM.imageSelection, matching: .images, preferredItemEncoding: .automatic) {
                CommunityImage()
            }
            .fullScreenCover(isPresented: $createCommunityVM.isCropViewDisplayed) {
                createCommunityVM.image = nil
            } content: {
                CropScreen(size: CGSize(width: 300, height: 300), image: createCommunityVM.image) { croppedImage, status in
                    if let croppedImage {
                        createCommunityVM.croppedImage = croppedImage
                    }
                }
            }
            
            if createCommunityVM.croppedImage != nil {
                Button {
                    removePhoto()
                } label: {
                    RemoveMediaButton(size: .medium)
                }
            }
        }
    }
    
    // MARK: - Community Image
    
    @ViewBuilder
    private func CommunityImage() -> some View {
        if let selectedImage = createCommunityVM.croppedImage {
            Image(uiImage: selectedImage)
                .resizable()
                .scaledToFit()
                .frame(width: 128, height: 128, alignment: .center)
        } else {
            Image(systemName: "camera.circle.fill")
                .resizable()
                .foregroundStyle(.gray)
                .scaledToFit()
                .frame(width: 128, height: 128, alignment: .center)
        }
    }
    
    // MARK: - Name
    
    @ViewBuilder
    private func Name() -> some View {
        TextField("Enter a Community Name", text: $createCommunityVM.communityNameInput)
            .textFieldStyle(.plain)
            .multilineTextAlignment(.center)
            .font(.title)
            .fontWeight(.bold)
    }
    
    // MARK: - Description
    
    @ViewBuilder
    private func Description() -> some View {
        VStack {
            HStack {
                Text("Description:")
                    .foregroundStyle(.gray)
                    .fontWeight(.bold)
                Spacer()
            }
            
            TextField("Briefly describe your Community...", text: $createCommunityVM.communityDescriptionInput, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...3)
                .focused($isDescriptionTextFieldFocused)
                .onReceive(createCommunityVM.communityDescriptionInput.publisher.last()) {
                    if ($0 as Character).asciiValue == 10 {
                        isDescriptionTextFieldFocused = false
                        createCommunityVM.communityDescriptionInput.removeLast()
                    }
                }
        }
    }
    
    // MARK: - Settings
    
    @ViewBuilder
    private func Settings() -> some View {
        VStack {
            Duration()
            
            Divider()
            
            Location()
            
            Divider()
            
            Private()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16).fill(.thinMaterial)
        )
    }
    
    // MARK: - Duration
    
    @ViewBuilder
    private func Duration() -> some View {
        HStack {
            Text("Duration:")
                .fontWeight(.bold)
                .frame(minWidth: 120, alignment: .leading) // Mantém largura fixa
            
            Spacer()
            
            HStack {
                Text("24 hours")
                    .bold()
                    .frame(width: 80, alignment: .trailing) // Mantém o tamanho fixo
                Image(systemName: "info.circle")
                    .onTapGesture {
                        createCommunityVM.isDurationInfoPopoverDisplayed = true
                    }
                    .popover(isPresented: $createCommunityVM.isDurationInfoPopoverDisplayed) {
                        Text("Communities are available for 24 hours only.")
                            .font(.caption)
                            .foregroundStyle(.gray)
                            .padding()
                            .presentationCompactAdaptation(.popover)
                    }
            }
            
        }
        .frame(height: 32)
        .foregroundStyle(.gray)
        .padding(.vertical, 4)
    }
    
    // MARK: - Location
    
    @ViewBuilder
    private func Location() -> some View {
        HStack {
            Text("Display Location:")
                .fontWeight(.bold)
                .frame(minWidth: 120, alignment: .leading) // Mesma largura do Duration
            
            Spacer()
            
            Toggle("", isOn: $createCommunityVM.isLocationVisible)
                .frame(width: 80, alignment: .trailing) // Mesmo tamanho do menu
        }
        .frame(height: 32)
        .foregroundStyle(.gray)
        .padding(.vertical, 4)
    }
    
    // MARK: - Private
    
    @ViewBuilder
    private func Private() -> some View {
        HStack {
            Text("Ask to join:")
                .fontWeight(.bold)
                .frame(minWidth: 120, alignment: .leading)
            
            Spacer()
            
            Toggle("", isOn: $createCommunityVM.isCommunityPrivate)
                .frame(width: 80, alignment: .trailing)
        }
        .frame(height: 32)
        .foregroundStyle(.gray)
        .padding(.vertical, 4)
    }
    
    // MARK: - Create
    
    @ViewBuilder
    private func Create() -> some View {
        if createCommunityVM.isCreatingCommunity {
            AYProgressButton(title: "Creating...")
        } else {
            AYButton(title: "Create Community") {
                Task {
                    try await createCommunity()
                }
            }
            .disabled(!createCommunityVM.areInputsValid())
        }
    }
    
    // MARK: - Disclaimer
    
    @ViewBuilder
    private func Disclaimer() -> some View {
        AYDisabledButton(title: "Only people nearby your community will be able to interact with it, even you.")
    }
    
    // MARK: - Private Methods
    
    private func createCommunity() async throws {
        locationManager.requestLocation()
        if let location = locationManager.location {
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            
            let token = try await authVM.getFirebaseToken()
            await createCommunityVM.posNewCommunity(latitude: latitude, longitude: longitude, token: token)
            dismiss()
        } else {
            createCommunityVM.overlayError = (true, ErrorMessage.locationDisabledErrorMessage)
        }
    }
    
    private func removePhoto() {
        createCommunityVM.image = nil
        createCommunityVM.croppedImage = nil
    }
}

#Preview {
    CreateCommunityScreen(
        communityVM: CommunityViewModel(),
        locationManager: LocationManager()
    )
    .environmentObject(AuthenticationViewModel())
}
