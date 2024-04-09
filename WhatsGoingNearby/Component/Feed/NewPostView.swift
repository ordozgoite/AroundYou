//
//  NewPostView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 07/04/24.
//

import SwiftUI

struct NewPostView: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    
    var body: some View {
        NavigationLink(destination: NewPostScreen().environmentObject(authVM)) {
            HStack {
                ProfilePicView(profilePic: authVM.profilePic, size: 32)
                
                Text("What's going on around you?")
                    .foregroundStyle(.gray)
                    .font(.subheadline)
                
                Spacer()
                
                Image(systemName: "square.and.pencil")
                    .foregroundStyle(.gray)
            }
            .padding()
            .frame(height: 64)
            .background(
                RoundedRectangle(cornerRadius: 8).fill(.thinMaterial)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NewPostView()
}
