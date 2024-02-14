//
//  ProfilePictureView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 14/02/24.
//

import SwiftUI

class ImageLoader: ObservableObject {
    
    @Published var downloadedData: Data?
    
    func downloadImage(url: String) {
        guard let imageURL = URL(string: url) else { return }
        
        URLSession.shared.dataTask(with: imageURL) { data, _, error in
            guard let data = data, error == nil else { return }
            
            DispatchQueue.main.async {
                self.downloadedData = data
            }
        }.resume()
    }
}

struct ProfilePictureView: View {
    
    let imageURL: String
    @State private var image: UIImage? = nil
    
    var body: some View {
        VStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Image("placeholder")
            }
        }
        .onAppear {
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

#Preview {
    ProfilePictureView(imageURL: "https://www.bloomberglinea.com/resizer/PLUNbQCzVan6SFJ1RQ3CcBj6js8=/600x0/filters:format(webp):quality(75)/cloudfront-us-east-1.images.arcpublishing.com/bloomberglinea/S5ZMXTXZINE2JBQAV7MECJA7KM.jpg")
}
