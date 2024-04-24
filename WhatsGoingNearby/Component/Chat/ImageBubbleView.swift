//
//  ImageBubbleView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 08/04/24.
//

import SwiftUI

enum ImageSource {
    case url
    case uiImage
}

struct ImageBubbleView: View {
    
    let source: ImageSource
    let imageUrl: String?
    let uiImage: UIImage?
    var isCurrentUser: Bool
    
    @State private var isFullScreenImageDisplayed = false
    
    var body: some View {
        switch source {
        case .url:
            ImageFromUrl()
        case .uiImage:
            ImageFromUIImage()
        }
    }
    
    //MARK: - URL
    
    @ViewBuilder
    private func ImageFromUrl() -> some View {
        PostImageView(imageURL: self.imageUrl!)
            .scaledToFill()
            .frame(width: 200, height: 256)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .aspectRatio(contentMode: .fill)
            .frame(width: 200, height: 256)
            .frame(maxWidth: .infinity, alignment: isCurrentUser ? .trailing : .leading)
            .padding(.bottom, 2)
            .onTapGesture {
                isFullScreenImageDisplayed = true
            }
            .fullScreenCover(isPresented: $isFullScreenImageDisplayed) {
                FullScreenImage(url: imageUrl!)
            }
    }
    
    //MARK: - UIImage
    
    @ViewBuilder
    private func ImageFromUIImage() -> some View {
        Image(uiImage: self.uiImage!)
            .resizable()
            .scaledToFill()
            .frame(width: 200, height: 256)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .aspectRatio(contentMode: .fill)
            .frame(width: 200, height: 256)
            .frame(maxWidth: .infinity, alignment: isCurrentUser ? .trailing : .leading)
            .padding(.bottom, 2)
//            .onTapGesture {
//                isFullScreenImageDisplayed = true
//            }
//            .fullScreenCover(isPresented: $isFullScreenImageDisplayed) {
//                FullScreenImage(url: imageUrl ?? "")
//            }
    }
}

//#Preview {
//    ImageBubbleView(imageUrl: "https://firebasestorage.googleapis.com:443/v0/b/aroundyou-b8364.appspot.com/o/post-image%2F8019D1A7-097F-45FA-B0FF-41959EC98789.jpg?alt=media&token=3c621a0c-46e2-405a-b5f5-3bff8f888e07", isCurrentUser: true)
//}
