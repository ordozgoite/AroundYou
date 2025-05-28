//
//  FullScreenUIImage.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 09/05/24.
//

import SwiftUI

struct FullScreenUIImage: View {
    
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ZoomableImageViewRepresentable(image: self.image)
            
            Exit()
        }
    }
    
    //MARK: - Exit
    
    @ViewBuilder
    private func Exit() -> some View {
        ZStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(.white)
                    .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}


//#Preview {
//    FullScreenUIImage()
//}
