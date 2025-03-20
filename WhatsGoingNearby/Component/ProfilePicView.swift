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
    
    @State private var image: UIImage? = nil
    let profilePic: String?
    let size: CGFloat
    
    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
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
        .onAppear {
            Task {
                await loadImage()
            }
        }
    }
    
    private func loadImage() async {
        if let url = profilePic {
            self.image = await KingfisherService.shared.loadImage(from: url)
        }
    }
}
