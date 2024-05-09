//
//  FullScreenUIImage.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 09/05/24.
//

import SwiftUI

struct FullScreenUIImage: View {
    
    let image: UIImage
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ZoomableImageView(image: self.image)
            
            Exit()
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
}

//#Preview {
//    FullScreenUIImage()
//}
