//
//  ProfileScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import SwiftUI

struct ProfileScreen: View {
    var body: some View {
        NavigationStack {
            VStack {
                ProfileHeader()
                
                Spacer()
            }
            .toolbar {
                ToolbarItem {
                    Button {
                        // open settings
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
        }
    }
    
    //MARK: - Profile Header
    
    @ViewBuilder
    private func ProfileHeader() -> some View {
        VStack {
            Image("shaq")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 128, height: 128)
                .clipShape(Circle())
            
            Text("Victor Rafael Ordozgoite")
                .font(.title)
                .fontWeight(.semibold)
            
            Text("@victorordozgoite")
                .foregroundStyle(.gray)
        }
    }
}

#Preview {
    ProfileScreen()
}
