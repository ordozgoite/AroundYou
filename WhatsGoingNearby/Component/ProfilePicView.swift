//
//  ProfilePicView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 15/02/24.
//

import SwiftUI

struct ProfilePicView: View {
    
    let profilePic: String?
    
    var body: some View {
        if let url = profilePic {
            URLImageView(imageURL: url)
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipShape(Circle())
        } else {
            Image(systemName: "person.circle.fill")
                .resizable()
                .foregroundStyle(.gray)
                .frame(width: 50, height: 50)
        }
            
    }
}
