//
//  URLNotTapableImageView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 16/05/25.
//

import SwiftUI

struct URLNotTapableImageView: View {
    
    let imageURL: String
    @State private var image: UIImage? = nil
    
    var body: some View {
        VStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Rectangle().fill(.gray)
            }
        }
        .onAppear {
            Task {
                await loadImage()
            }
        }
    }
    
    private func loadImage() async {
        self.image = await KingfisherService.shared.loadImage(from: imageURL)
    }
}

#Preview {
//    URLNotTapableImageView()
}
