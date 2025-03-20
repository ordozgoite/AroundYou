//
//  FullScreenPostImage.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 31/03/24.
//

import SwiftUI

struct FullScreenUrlImage: View {
    
    let url: String
    
    @State private var loadedImage: UIImage? = nil
    @State private var opacity: Double = 1.0
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ZoomableImage()
            
            Exit()
        }
        .onAppear {
            Task {
                startAnimation()
                await loadImage()
            }
        }
    }
    
    //MARK: - Zoomable Image
    
    @ViewBuilder
    private func ZoomableImage() -> some View {
        if let img = loadedImage {
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
    
    private func startAnimation() {
        withAnimation(Animation.easeInOut(duration: 1).repeatForever()) {
            self.opacity = 0.5
        }
    }
    
    private func loadImage() async {
        self.loadedImage = await KingfisherService.shared.loadImage(from: self.url)
    }
}

//#Preview {
//    FullScreenPostImage(isPresented: .constant(true), url: "https:\/\/firebasestorage.googleapis.com:443\/v0\/b\/aroundyou-b8364.appspot.com\/o\/post-image%2FCE622063-2DDD-4A9F-B1B1-9EF759A3FF0A.jpg?alt=media&token=780f6359-593f-420e-b53b-5b15877cf838")
//}
