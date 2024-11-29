//
//  DiscoverUserView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 27/10/24.
//

import SwiftUI

struct DiscoverUserView: View {
    
    let userImageURL: String
    let userName: String
    let gender: Gender
    let age: Int
    
    var body: some View {
        VStack {
            ProfilePicView(profilePic: userImageURL, size: 100)
            
            Text(userName)
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading) {
                Text("· \(age) years old")
                Text("· \(gender.title.stringKey)")
            }
            .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical)
        .background(
            Color.white.opacity(0.2)
                .background(BlurView())
        )
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)
        .padding(.horizontal)
    }
}

#Preview {
    DiscoverUserView(
        userImageURL: "https://br.web.img2.acsta.net/pictures/19/04/29/20/14/1886009.jpg",
        userName: "Megan Fox",
        gender: .cisFemale,
        age: 38
    )
}
