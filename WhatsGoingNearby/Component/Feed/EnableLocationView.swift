//
//  LocationSettingsView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 05/03/24.
//

import SwiftUI

struct EnableLocationView: View {
    var body: some View {
        VStack {
            Image(systemName: "location.slash")
                .resizable()
                .frame(width: 64, height: 64, alignment: .center)
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(.gray)
            
            Text("The **location service** is disabled. Please enable it to unlock the full functionality of AroundYou.")
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
                .padding()
            
            Button(action: {
                guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
                    return
                }
                UIApplication.shared.open(settingsURL)
            }) {
                Label(
                    title: { Text("Enable Location Service") },
                    icon: { Image(systemName: "location.fill") }
                )
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
    }
}

#Preview {
    EnableLocationView()
}
