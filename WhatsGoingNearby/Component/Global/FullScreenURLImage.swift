//
//  FullScreenURLImage.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 25/08/25.
//

import SwiftUI

// Exibe uma imagem remota em tela cheia.
// Diferente da FullScreenUIImage, o download acontece aqui dentro:
// o botão de fechar e o arrastar-para-fechar ficam disponíveis desde o primeiro frame,
// inclusive enquanto a imagem ainda está carregando.

struct FullScreenURLImage: View {

    let imageURL: String
    @Environment(\.dismiss) private var dismiss
    @State private var image: UIImage? = nil
    @State private var isLoading: Bool = true
    @State private var zoomScale: CGFloat = 1

    var body: some View {
        DragToDismissContainer(
            isEnabled: zoomScale <= 1.01,
            onDismiss: { dismiss() }
        ) {
            Content()
                .ignoresSafeArea()
        } chrome: {
            Exit()
        }
        .onAppear {
            Task {
                await loadImage()
            }
        }
    }

    //MARK: - Content

    @ViewBuilder
    private func Content() -> some View {
        if let image = self.image {
            ZoomableImageViewRepresentable(image: image) { scale in
                zoomScale = scale
            }
        } else {
            Placeholder()
        }
    }

    @ViewBuilder
    private func Placeholder() -> some View {
        ZStack {
            if isLoading {
                ProgressView()
                    .tint(.white)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.largeTitle)
                    Text("We couldn’t load this image.")
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(.white)
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    //MARK: - Auxiliary

    private func loadImage() async {
        self.image = await KingfisherService.shared.loadImage(from: self.imageURL)
        self.isLoading = false
    }
}
