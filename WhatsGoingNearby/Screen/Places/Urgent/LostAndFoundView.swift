//
//  LostAndFoundView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 24/03/25.
//

import SwiftUI

struct LostAndFoundView: View {
    @Binding var isViewDisplayed: Bool
    
    @State private var itemType: String = ""
    @State private var itemDescription: String = ""
    @State private var lostLocation: String = ""
    @State private var lostDate: Date = Date()
    @State private var rewardOffer: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                Description()
                
                LocationAndDate()
                
                Reward()
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
            
            TextField("Item description", text: $itemDescription)
                .textFieldStyle(.plain)
        }
    }
    
    // MARK: - Location & Date
    
    @ViewBuilder
    private func LocationAndDate() -> some View {
        Section {
            TextField("Where did you lose it?", text: $lostLocation)
                .textFieldStyle(.plain)
            
            DatePicker("Approximate date and time", selection: $lostDate, displayedComponents: [.date, .hourAndMinute])
        } header: {
            Text("Location and Date")
        } footer: {
            Text("Provide the location and time when you lost the item to help with the search.")
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

#Preview {
    LostAndFoundView(isViewDisplayed: .constant(true))
}
