//
//  ProfilePictureView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 14/02/24.
//

import SwiftUI

struct PostImageView: View {
    
    let imageURL: String
    @State private var image: UIImage? = nil
    @State private var opacity: Double = 1.0
    
    var body: some View {
        VStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Rectangle()
                    .foregroundStyle(.gray)
                    .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1).repeatForever()) {
                opacity = 0.5
            }
            loadImage(from: URL(string: imageURL)!)
        }
    }
    
    private func loadImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Failed to load image from URL:", error ?? "Unknown error")
                return
            }
            DispatchQueue.main.async {
                image = UIImage(data: data)
            }
        }.resume()
    }
}
