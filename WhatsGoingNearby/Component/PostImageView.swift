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
                .onTapGesture {
                    isZoomableImageDisplayed = true
                }
                .fullScreenCover(isPresented: $isZoomableImageDisplayed) {
                    FullScreenUIImage(image: image)
                }
        } else {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .onTapGesture {
                    isZoomableImageDisplayed = true
                }
                .fullScreenCover(isPresented: $isZoomableImageDisplayed) {
                    FullScreenUIImage(image: image)
                }
        }
    }

    private func feedAspectRatio(for image: UIImage) -> CGFloat {
        guard image.size.height > 0 else { return 16 / 9 }
        return PostMediaLayout.constrainedAspectRatio(image.size.width / image.size.height)
    }
}
