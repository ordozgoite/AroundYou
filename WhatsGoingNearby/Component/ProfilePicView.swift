//
//  ProfilePicView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 15/02/24.
//

import SwiftUI

struct ProfilePicView: View {
    
    init(profilePic: String?, size: CGFloat = 50) {
        self.profilePic = profilePic
        self.size = size
    }
    
    let profilePic: String?
    let size: CGFloat
    
    var body: some View {
        if let url = profilePic {
            URLImageView(imageURL: url)
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            Image(systemName: "person.circle.fill")
                .resizable()
                .foregroundStyle(.gray)
                .frame(width: size, height: size)
        }
            
    }
}
