//
//  FullScreenPostImage.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 31/03/24.
//

import SwiftUI

struct FullScreenPostImage: View {
    
    let url: String
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            PostImageView(imageURL: url)
                .scaledToFit()
                .frame(width: screenWidth, height: (screenWidth / 3) * 4)
            
            Image(systemName: "xmark")
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding()
                .onTapGesture {
                    presentationMode.wrappedValue.dismiss()
                }
        }
    }
}

//#Preview {
//    FullScreenPostImage(isPresented: .constant(true), url: "https:\/\/firebasestorage.googleapis.com:443\/v0\/b\/aroundyou-b8364.appspot.com\/o\/post-image%2FCE622063-2DDD-4A9F-B1B1-9EF759A3FF0A.jpg?alt=media&token=780f6359-593f-420e-b53b-5b15877cf838")
//}
