import SwiftUI
import Kingfisher

struct PostImageView: View {
    
    let imageURL: String
    @State private var image: UIImage? = nil
    @State private var opacity: Double = 1.0
    
    var body: some View {
        VStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Rectangle()
                    .foregroundStyle(.gray)
                    .opacity(opacity)
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
}
