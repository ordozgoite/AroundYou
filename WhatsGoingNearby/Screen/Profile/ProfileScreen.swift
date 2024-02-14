//
//  ProfileScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import SwiftUI

struct ProfileScreen: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    
    var body: some View {
        NavigationStack {
            VStack {
                ProfileHeader()
                
                Spacer()
            }
            .toolbar {
                ToolbarItem {
                    NavigationLink {
                        SettingsScreen()
                            .environmentObject(authVM)
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
            ProfilePictureView(imageURL: authVM.profilePic)
                .aspectRatio(contentMode: .fill)
                .frame(width: 128, height: 128)
                .clipShape(Circle())
            
            Text(authVM.name)
                .font(.title)
                .fontWeight(.semibold)
            
            Text("My bio")
                .foregroundStyle(.gray)
        }
    }
}

#Preview {
    ProfileScreen()
}
