//
//  RemoveMediaButton.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 22/02/25.
//

import SwiftUI

struct RemoveMediaButton: View {
    
    enum ButtonSize {
        case small
        case medium
    }
    
    let size: ButtonSize
    
    private var buttonSize: CGFloat {
        return switch size {
        case .small:
            20
        case .medium:
            28
        }
    }
    
    var body: some View {
        Image(systemName: "x.circle")
            .resizable()
            .scaledToFit()
            .foregroundStyle(.white)
            .background(Circle().fill(.gray))
            .frame(width: buttonSize, height: buttonSize, alignment: .center)
    }
}

#Preview {
    RemoveMediaButton(size: .medium)
}
