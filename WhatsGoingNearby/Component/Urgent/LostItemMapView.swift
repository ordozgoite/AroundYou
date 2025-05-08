//
//  LostItemMapView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 25/03/25.
//

import SwiftUI
import MapKit

struct LostItemMapView: View {
    
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            MapPickerView(selectedCoordinate: $selectedCoordinate)
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle("Where did you lose it?")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Save") {
                            dismiss()
                        }
                        .disabled(selectedCoordinate == nil)
                    }
                    
                    ToolbarItem(placement: .bottomBar) {
                        Text("Tap on the aproximmate location.")
                            .foregroundColor(.gray)
                    }
                }
        }
    }
}
