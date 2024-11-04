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
            
            VStack {
                Text("· \(age) years old")
                Text("· \(gender.rawValue)")
            }
            .foregroundStyle(.gray)
        }
    }
}

#Preview {
    DiscoverUserView(
        userImageURL: "https://br.web.img2.acsta.net/pictures/19/04/29/20/14/1886009.jpg",
        userName: "Megan Fox",
        gender: .female,
        age: 38
    )
}
