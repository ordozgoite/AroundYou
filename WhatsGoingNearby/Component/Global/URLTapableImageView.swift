//
//  ProfilePictureView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 14/02/24.
//

import SwiftUI

struct URLTapableImageView: View {
    
    let imageURL: String
    @State private var image: UIImage? = nil
    @State private var isZoomableImageDisplayed: Bool = false
    
    var body: some View {
        VStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .onTapGesture {
                        isZoomableImageDisplayed = true
                    }
                    .fullScreenCover(isPresented: $isZoomableImageDisplayed) {
                        FullScreenUIImage(image: image)
                    }
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
    URLTapableImageView(imageURL: "https://www.bloomberglinea.com/resizer/PLUNbQCzVan6SFJ1RQ3CcBj6js8=/600x0/filters:format(webp):quality(75)/cloudfront-us-east-1.images.arcpublishing.com/bloomberglinea/S5ZMXTXZINE2JBQAV7MECJA7KM.jpg")
}
