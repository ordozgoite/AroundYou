//
//  LostAndFoundView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 24/03/25.
//

import SwiftUI
import PhotosUI

struct LostAndFoundView: View {
    @Binding var isViewDisplayed: Bool
    
    @State private var itemType: String = ""
    @State private var itemDescription: String = ""
    @State private var lostLocation: String = ""
    @State private var lostItemCoordinate: CLLocationCoordinate2D?
    @State private var lostDate: Date = Date()
    @State private var rewardOffer: Bool = false
    
    @State private var imageSelection: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    
    var body: some View {
        NavigationStack {
            Form {
                Description()
                
                Picture()
                
                LocationAndDate()
                
                Reward()
            }
            .onChange(of: imageSelection) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                        selectedImage = image
                    }
                }
            }
            .navigationBarTitle("Lost & Found")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        self.isViewDisplayed = false
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Submit") {
                        // TODO: Post LostAndFound
                    }
                }
            }
        }
    }
    
    // MARK: - Description
    
    @ViewBuilder
    private func Description() -> some View {
        Section("Lost Item Information") {
            TextField("What did you lose?", text: $itemType)
                .textFieldStyle(.plain)
            
            TextField("Item description (optional)", text: $itemDescription)
            .textFieldStyle(.plain)        }
    }
    
    // MARK: - Picture
    
    @ViewBuilder
    private func Picture() -> some View {
        Section(header: Text("Add a Picture (Optional)")) {
            ZStack(alignment: .topTrailing) {
                PhotosPicker(selection: $imageSelection, matching: .images) {
                    ItemImage()
                }
                
                if selectedImage != nil {
                    Button {
                        removePhoto()
                    } label: {
                        RemoveMediaButton(size: .medium)
                    }
                }
            }
        }
    }
    
    // MARK: - Item Image
    
    @ViewBuilder
    private func ItemImage() -> some View {
        
        if let image = selectedImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 200)
                .listRowBackground(Color(.systemGroupedBackground))
        } else {
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
    
    // MARK: - Location & Date
    
    @ViewBuilder
    private func LocationAndDate() -> some View {
        Section {
            TextField("Describe the location (optional)", text: $lostLocation)
                .textFieldStyle(.plain)
            
            NavigationLink {
                LostItemMapView(selectedCoordinate: $lostItemCoordinate)
            } label: {
                Label(
                    lostItemCoordinate == nil ? "Choose location" : "\(lostItemCoordinate!.latitude), \(lostItemCoordinate!.longitude)",
                    systemImage: "mappin"
                )
                .foregroundStyle(.blue)
            }
            
            
            DatePicker("Date and time", selection: $lostDate, displayedComponents: [.date, .hourAndMinute])
        } header: {
            Text("Location and Date")
        } footer: {
            Text("Provide the approximate location and time when you lost the item to help with the search.")
        }
    }
    
    // MARK: - Reward
    
    @ViewBuilder
    private func Reward() -> some View {
        Section {
            Toggle("Offer a reward?", isOn: $rewardOffer)
                .toggleStyle(SwitchToggleStyle())
        } header: {
            Text("Reward")
        } footer: {
            Text("You can offer a reward to encourage people to return your item.")
        }
    }
}

// MARK: - Private Methods

extension LostAndFoundView {
    private func removePhoto() {
        self.imageSelection = nil
        self.selectedImage = nil
    }
}

#Preview {
    LostAndFoundView(isViewDisplayed: .constant(true))
}
