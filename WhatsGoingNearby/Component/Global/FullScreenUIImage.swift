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
    @State private var zoomScale: CGFloat = 1
    
    var body: some View {
        DragToDismissContainer(
            isEnabled: zoomScale <= 1.01,
            onDismiss: { dismiss() }
        ) {
            ZoomableImageViewRepresentable(image: image) { scale in
                zoomScale = scale
            }
            .ignoresSafeArea()
        } chrome: {
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
