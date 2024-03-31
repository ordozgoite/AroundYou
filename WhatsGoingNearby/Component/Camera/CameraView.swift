//
//  CameraView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 31/03/24.
//

import SwiftUI

struct CameraView: View {
    
    @Binding var image: UIImage?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            accessCameraView(selectedImage: $image)
        }
    }
}

//#Preview {
//    CameraView(image: .constant(UIImage(""))
//}
