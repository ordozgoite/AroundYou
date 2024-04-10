//
//  FullScreenPostImage.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 31/03/24.
//

import SwiftUI

struct FullScreenImage: View {
    
    let url: String
    
    @State private var image: UIImage? = nil
    @State private var opacity: Double = 1.0
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ZoomableImage()
            
            Exit()
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1).repeatForever()) {
                opacity = 0.5
            }
            loadImage(from: URL(string: url)!)
        }
    }
    
    //MARK: - Zoomable Image
    
    @ViewBuilder
    private func ZoomableImage() -> some View {
        if let img = image {
            ZoomableImageView(image: img)
        } else {
            Rectangle()
                .foregroundStyle(.gray)
                .opacity(opacity)
        }
    }
    
    //MARK: - Exit
    
    @ViewBuilder
    private func Exit() -> some View {
        Button {
            presentationMode.wrappedValue.dismiss()
        } label: {
            Image(systemName: "xmark")
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding()
        }
    }
    
    //MARK: - Private Method
    
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

//#Preview {
//    FullScreenPostImage(isPresented: .constant(true), url: "https:\/\/firebasestorage.googleapis.com:443\/v0\/b\/aroundyou-b8364.appspot.com\/o\/post-image%2FCE622063-2DDD-4A9F-B1B1-9EF759A3FF0A.jpg?alt=media&token=780f6359-593f-420e-b53b-5b15877cf838")
//}
