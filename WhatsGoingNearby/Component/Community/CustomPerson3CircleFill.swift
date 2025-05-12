//
//  CustomPerson3CircleFill.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 14/02/25.
//

import SwiftUI

struct CustomPerson3CircleFill: View {
    
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .fill(.gray)
                .frame(width: size, height: size)

            Image(systemName: "person.3.fill")
                .resizable()
                .foregroundColor(.white)
                .scaledToFit()
                .padding(size / 10)
                .frame(width: size, height: size)
        }
    }
}

#Preview {
    CustomPerson3CircleFill(size: 160)
}
