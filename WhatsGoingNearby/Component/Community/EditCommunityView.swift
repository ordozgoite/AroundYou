//
//  EditCommunityView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 21/02/25.
//

import SwiftUI
import PhotosUI

struct EditCommunityView: View {
    
    let prevCommunityName: String
    let prevCommunityImageUrl: String?
    
    @ObservedObject var communityDetailVM: CommunityDetailViewModel
    
    @Binding var isViewDisplayed: Bool
    @State private var newName: String = ""
    @State private var newImageUrl: String?
    
    var body: some View {
        NavigationStack {
            VStack {
                EditCommunityImage()
                
                Name()
            }
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
            .onAppear {
                setInputValues()
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
                        communityDetailVM.croppedImage = croppedImage
                    }
                }
            }
            
            if communityDetailVM.croppedImage != nil {
                Button {
                    removePhoto()
                } label: {
                    Image(systemName: "xmark")
                        .resizable()
                        .frame(width: 16, height: 16, alignment: .center)
                }
            }
        }
    }
    
    // MARK: - Community Image
    
    @ViewBuilder
    private func CommunityImage() -> some View {
        if let selectedImage = communityDetailVM.croppedImage {
            Image(uiImage: selectedImage)
                .resizable()
                .scaledToFit()
                .frame(width: 128, height: 128, alignment: .center)
        } else {
            CustomPerson3CircleFill(size: 128)
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
        if communityDetailVM.isEditingDescription {
            ProgressView()
        } else {
            Button("Save") {
                Task {
//                    try await saveDescription()
                }
            }
        }
    }
}

// MARK: - Private Methods

extension EditCommunityView {
    private func setInputValues() {
        newName = prevCommunityName
        newImageUrl = prevCommunityImageUrl
    }
    
    private func removePhoto() {
        communityDetailVM.image = nil
        communityDetailVM.croppedImage = nil
    }
}

#Preview {
    EditCommunityView(prevCommunityName: "Jogadores de Catan", prevCommunityImageUrl: nil, communityDetailVM: CommunityDetailViewModel(), isViewDisplayed: .constant(true))
}
