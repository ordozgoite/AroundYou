//
//  CameraView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 31/03/24.
//

import SwiftUI

struct CameraView: View {
    
    let sendImage: (UIImage) -> ()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            accessCameraView(sendImage: sendImage)
        }
    }
}

//#Preview {
//    CameraView(image: .constant(UIImage(""))
//}
