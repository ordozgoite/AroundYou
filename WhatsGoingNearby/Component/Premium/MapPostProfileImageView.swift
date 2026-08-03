//
//  MapPostProfileImageView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 10/05/26.
//

import SwiftUI

struct MapPostProfileImageView: View {
    
    let profilePic: String?
    let size: CGFloat
    
    var body: some View {
        if let profilePic,
           let url = URL(string: profilePic) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    placeholder
                    
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                        .clipped()
                    
                case .failure:
                    placeholder
                    
                @unknown default:
                    placeholder
                }
            }
        } else {
            placeholder
        }
    }
    
    private var placeholder: some View {
        Circle()
            .fill(.gray.opacity(0.18))
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.42))
                    .foregroundStyle(.secondary)
            }
    }
}

//#Preview {
//    MapPostProfileImageView()
//}
