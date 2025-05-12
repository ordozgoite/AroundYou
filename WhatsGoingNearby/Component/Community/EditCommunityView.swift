//
//  EditCommunityView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 21/02/25.
//

import SwiftUI
import PhotosUI

struct EditCommunityView: View {
    
    let communityId: String
    let prevCommunityName: String
    let prevCommunityImageUrl: String?
    let updateCommunityInfo: () -> ()
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @ObservedObject var communityDetailVM: CommunityDetailViewModel
    @FocusState private var isEditingName: Bool
    
    @Binding var isViewDisplayed: Bool
    
    var body: some View {
        NavigationStack {
            VStack {
                EditCommunityImage()
                
                Name()
                
                Spacer()
            }
            .padding()
            .navigationTitle("Edit Community")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Cancel()
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Save()
                }
            }
            .onChange(of: communityDetailVM.imageSelection) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                        communityDetailVM.image = image
                        communityDetailVM.isCropViewDisplayed = true
                    }
                }
            }
            .onAppear {
                setInputValues()
                displayKeyboard()
            }
        }
    }
    
    // MARK: - Image
    
    @ViewBuilder
    private func EditCommunityImage() -> some View {
        ZStack(alignment: .topTrailing) {
            PhotosPicker(selection: $communityDetailVM.imageSelection, matching: .images, preferredItemEncoding: .automatic) {
                CommunityImage()
            }
            .fullScreenCover(isPresented: $communityDetailVM.isCropViewDisplayed) {
                communityDetailVM.image = nil
            } content: {
                CropScreen(size: CGSize(width: 300, height: 300), image: communityDetailVM.image) { croppedImage, status in
                    if let croppedImage {
                        displayNewImage(from: croppedImage)
                    }
                }
            }
            
            if communityDetailVM.communityImageDisplaySource != .none {
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
        switch communityDetailVM.communityImageDisplaySource {
        case .none:
            CustomPerson3CircleFill(size: 128)
        case .url:
            CommunityImageView(imageUrl: prevCommunityImageUrl, size: 128)
        case .uiImage:
            Image(uiImage: communityDetailVM.croppedImage!)
                .resizable()
                .scaledToFit()
                .frame(width: 128, height: 128, alignment: .center)
        }
    }
    
    // MARK: - Name
    
    @ViewBuilder
    private func Name() -> some View {
        TextField("Enter a Community Name", text: $communityDetailVM.communityNameInput)
            .textFieldStyle(.plain)
            .multilineTextAlignment(.center)
            .font(.title)
            .fontWeight(.bold)
            .focused($isEditingName)
    }
    
    // MARK: - Cancel
    
    @ViewBuilder
    private func Cancel() -> some View {
        Button("Cancel") {
            self.isViewDisplayed = false
        }
    }
    
    // MARK: - Save
    
    @ViewBuilder
    private func Save() -> some View {
        if communityDetailVM.isEditingCommunity {
            ProgressView()
        } else {
            Button("Save") {
                Task {
                    try await saveCommunityInfo()
                }
            }
            .disabled(!isCommunityUpdateValid())
        }
    }
}

// MARK: - Private Methods

extension EditCommunityView {
    private func setInputValues() {
        communityDetailVM.communityNameInput = prevCommunityName
        communityDetailVM.communityImageDisplaySource = prevCommunityImageUrl == nil ? .none : .url
    }
    
    private func displayKeyboard() {
        self.isEditingName = true
    }
    
    private func removePhoto() {
        communityDetailVM.image = nil
        communityDetailVM.croppedImage = nil
        communityDetailVM.communityImageDisplaySource = .none
    }
    
    private func displayNewImage(from image: UIImage) {
        communityDetailVM.croppedImage = image
        communityDetailVM.communityImageDisplaySource = .uiImage
    }
    
    private func isCommunityUpdateValid() -> Bool {
        let nameIsValid = !communityDetailVM.communityNameInput.isEmpty
        let hasChanges = hasCommunityInfoChanged()
        return nameIsValid && hasChanges
    }
    
    private func hasCommunityInfoChanged() -> Bool {
        let nameChanged = communityDetailVM.communityNameInput != prevCommunityName
        let imageChanged = previousImageSource() != communityDetailVM.communityImageDisplaySource
        return nameChanged || imageChanged
    }
    
    private func previousImageSource() -> ImageDisplaySource {
        return prevCommunityImageUrl == nil ? .none : .url
    }
    
    private func saveCommunityInfo() async throws {
        do {
            try await editCommunity()
        } catch {
            print("❌ Error editing community: \(error.localizedDescription)")
        }
    }
    
    private func editCommunity() async throws {
        let token = try await authVM.getFirebaseToken()
        try await communityDetailVM.editCommunity(communityId: self.communityId, prevImageUrl: self.prevCommunityImageUrl, token: token)
        self.isViewDisplayed = false
        updateCommunityInfo()
    }
}

#Preview {
    EditCommunityView(communityId: UUID().uuidString, prevCommunityName: "Jogadores de Catan", prevCommunityImageUrl: nil, updateCommunityInfo: {}, communityDetailVM: CommunityDetailViewModel(), isViewDisplayed: .constant(true))
}
