import SwiftUI
import Kingfisher

enum PostMediaLayout {
    static let minimumAspectRatio: CGFloat = 4 / 5
    static let maximumAspectRatio: CGFloat = 16 / 9

    static func constrainedAspectRatio(_ aspectRatio: CGFloat) -> CGFloat {
        guard aspectRatio.isFinite, aspectRatio > 0 else { return maximumAspectRatio }
        return min(max(aspectRatio, minimumAspectRatio), maximumAspectRatio)
    }
}

struct PostImageView: View {
    
    let imageURL: String
    var usesFeedLayout = false
    /// Quando `false`, a view não instala gesto de toque nenhum: quem embrulha essa
    /// view fica responsável por abrir a tela cheia. Evita que o gesto interno
    /// (que só existe depois que a imagem carrega) concorra com o gesto do pai.
    var handlesTapToFullScreen = true
    @State private var image: UIImage? = nil
    @State private var opacity: Double = 1.0
    @State private var isZoomableImageDisplayed: Bool = false
    
    var body: some View {
        VStack {
            if let image = image {
                loadedImage(image)
            } else {
                Rectangle()
                    .foregroundStyle(.gray)
                    .opacity(opacity)
                    .aspectRatio(usesFeedLayout ? 16 / 9 : nil, contentMode: .fit)
            }
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1).repeatForever()) {
                opacity = 0.5
            }
            Task {
                await loadImage()
            }
        }
    }
    
    private func loadImage() async {
        self.image = await KingfisherService.shared.loadImage(from: self.imageURL)
    }

    @ViewBuilder
    private func loadedImage(_ image: UIImage) -> some View {
        if usesFeedLayout {
            Color.clear
                .aspectRatio(feedAspectRatio(for: image), contentMode: .fit)
                .overlay {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                }
                .clipped()
                .contentShape(Rectangle())
                .presentsFullScreenImage(
                    isEnabled: handlesTapToFullScreen,
                    isPresented: $isZoomableImageDisplayed,
                    image: image
                )
        } else {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .presentsFullScreenImage(
                    isEnabled: handlesTapToFullScreen,
                    isPresented: $isZoomableImageDisplayed,
                    image: image
                )
        }
    }

    private func feedAspectRatio(for image: UIImage) -> CGFloat {
        guard image.size.height > 0 else { return 16 / 9 }
        return PostMediaLayout.constrainedAspectRatio(image.size.width / image.size.height)
    }
}

private extension View {

    @ViewBuilder
    func presentsFullScreenImage(
        isEnabled: Bool,
        isPresented: Binding<Bool>,
        image: UIImage
    ) -> some View {
        if isEnabled {
            self
                .onTapGesture {
                    isPresented.wrappedValue = true
                }
                .fullScreenCover(isPresented: isPresented) {
                    FullScreenUIImage(image: image)
                }
        } else {
            self
        }
    }
}
