//
//  LostItemDetailScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 01/05/25.
//

import SwiftUI

//let lostDate: Double
//let hasReward: Bool

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
                        if let url = lostItem.imageUrl {
                            URLImageView(imageURL: url)
                                .scaledToFit()
                                .frame(height: 256)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .listRowBackground(Color(.systemGroupedBackground))
                        }
                        
                        Section("Item Info") {
                            Text(lostItem.name)
                            
                            if let description = lostItem.description {
                                Text(description)
                            }
                        }
                        
                        if lostItem.hasReward {
                            Label("Offers Reward.", systemImage: "dollarsign")
                        }
                        
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
                }
            }
            .navigationTitle("Lost Item")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                Task {
                    let token = try await authVM.getFirebaseToken()
                    await vm.getLostItem(withId: self.lostItemId, token: token)
                }
            }
        }
    }
}

#Preview {
    LostItemDetailScreen(lostItemId: UUID().uuidString)
}
