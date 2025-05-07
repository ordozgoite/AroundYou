//
//  LostItemDetailScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 01/05/25.
//

import SwiftUI

struct LostItemDetailScreen: View {
    
    let lostItemId: String
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var vm = LostItemDetailViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                if vm.isLoading {
                   ProgressView()
                } else if let lostItem = vm.lostItem {
                    Form {
                        Image(forLostItem: lostItem)
                        
                        Info(forLostItem: lostItem)
                        
                        Reward(lostItem)
                        
                        Location(forLostItem: lostItem)
                    }
                }
            }
            .navigationTitle("Lost Item")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                FoundButton()
            }
            .onAppear {
                Task {
                    let token = try await authVM.getFirebaseToken()
                    await vm.getLostItem(withId: self.lostItemId, token: token)
                }
            }
        }
    }
    
    // MARK: - Lost Item Image
    
    @ViewBuilder
    private func Image(forLostItem lostItem: LostItem) -> some View {
        if let url = lostItem.imageUrl {
            URLImageView(imageURL: url)
                .scaledToFit()
                .frame(height: 256)
                .frame(maxWidth: .infinity, alignment: .center)
                .listRowBackground(Color(.systemGroupedBackground))
        }
    }
    
    // MARK: - Info
    
    @ViewBuilder
    private func Info(forLostItem lostItem: LostItem) -> some View {
        Section("Item Info") {
            Text(lostItem.name)
            
            if let description = lostItem.description {
                Text(description)
            }
        }
    }
    
    // MARK: - Info
    
    @ViewBuilder
    private func Reward(_ lostItem: LostItem) -> some View {
        if lostItem.hasReward {
            Label("Offers Reward.", systemImage: "dollarsign")
        }
    }
    
    // MARK: - Location
    
    @ViewBuilder
    private func Location(forLostItem lostItem: LostItem) -> some View {
        Section("Location") {
            Text("Lost at ")
            +
            Text(lostItem.lostDate.convertTimestampToDate().formatDatetoMessage())
            
            if let locationDescription = lostItem.locationDescription {
                Text(locationDescription)
            }
            
            MapView(latitude: lostItem.latitude, longitude: lostItem.longitude)
                .frame(height: 256)
        }
    }
    
    // MARK: - Found
    
    @ViewBuilder
    private func FoundButton() -> some View {
        if vm.lostItem?.userUid == LocalState.currentUserUid {
            if !(vm.lostItem?.wasFound ?? false) {
                Button("Found") {
                    Task {
                        let token = try await authVM.getFirebaseToken()
                        await vm.setItemAsFound(lostItemId: self.lostItemId, token: token)
                    }
                }
            }
        }
    }
}

#Preview {
    LostItemDetailScreen(lostItemId: UUID().uuidString)
}
