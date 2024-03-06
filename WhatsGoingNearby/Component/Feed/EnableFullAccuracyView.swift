//
//  EnableFullAccuracyView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 06/03/24.
//

import SwiftUI

struct EnableFullAccuracyView: View {
    var body: some View {
        VStack {
            Image(systemName: "location.slash.circle")
                .resizable()
                .frame(width: 64, height: 64, alignment: .center)
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(.gray)
            
            Text("The **precise location** is disabled. Please enable it to unlock the full functionality of AroundYou.")
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
                    title: { Text("Enable Precise Location") },
                    icon: { Image(systemName: "location.viewfinder") }
                )
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
    }
}

#Preview {
    EnableFullAccuracyView()
}
