//
//  HeartView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 21/03/24.
//

import SwiftUI

struct HeartView: View {
    
    @Binding var isLiked: Bool
    
    var tap: () -> ()
    
    var body: some View {
        Button {
            tap()
        } label: {
            ZStack {
                Heart(Image(systemName: "heart.fill"), show: isLiked)
                Heart(Image(systemName: "heart"), show: !isLiked)
            }
        }
    }
    
    //MARK: - Heart
    
    @ViewBuilder
    private func Heart(_ image: Image, show: Bool) -> some View {
        image
            .tint(isLiked ? .red : .gray)
            .scaleEffect(show ? 1 : 0)
            .opacity(show ? 1 : 0)
            .animation(.interpolatingSpring(stiffness: 170, damping: 15), value: show)
    }
}

#Preview {
    HeartView(isLiked: .constant(true), tap: {})
}
