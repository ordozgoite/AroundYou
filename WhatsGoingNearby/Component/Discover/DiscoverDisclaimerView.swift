//
//  DiscoverDisclaimerView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 06/12/24.
//

import SwiftUI

struct DisclaimerTag: Hashable {
    let systemImage: String
    let title: String
    let text: String
    let color: Color
}

struct DiscoverDisclaimerView: View {
    
    private let disclaimers: [DisclaimerTag] = [
        DisclaimerTag(systemImage: "location.viewfinder", title: "Discover AroundYou", text: "Your location will be used to discover other users.", color: .gray),
        DisclaimerTag(systemImage: "lock.shield.fill", title: "Data Protection", text: "Your precise location will not be shared with other users", color: .blue),
        DisclaimerTag(systemImage: "person.fill.checkmark", title: "Data Control", text: "You have full control over your personal information.", color: .green)
    ]
    
    let agree: () -> ()
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                
                VStack(alignment: .leading, spacing: 32) {
                    ForEach(disclaimers, id: \.self) { disclaimer in
                        HStack(spacing: 32) {
                            Image(systemName: disclaimer.systemImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .foregroundColor(disclaimer.color)
                            
                            VStack(alignment: .leading) {
                                Text(disclaimer.title)
                                    .fontWeight(.bold)
                                
                                Text(disclaimer.text)
                            }
                        }
                    }
                }
                
                Spacer()
                
                Button {
                    agree()
                } label: {
                    Text("Continue")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Text("[Learn More](https://aroundyou3.wordpress.com/policy-privacy)")
            }
            .padding()
            
            .navigationTitle("Data & Privacy")
        }
    }
}

#Preview {
    DiscoverDisclaimerView(agree: {})
}
