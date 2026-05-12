//
//  EmptyFeedView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 16/02/24.
//

import SwiftUI

struct EmptyFeedBackground: View {
    var body: some View {
        GeometryReader { geometry in
            LottieView(name: "radar", loopMode: .loop)
                .frame(
                    width: geometry.size.width,
                    height: geometry.size.height
                )
                .opacity(0.22)
                .scaleEffect(2)
                .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }
}

struct EmptyFeedMessage: View {
    var retry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "location.magnifyingglass")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 50, height: 50)
                .foregroundStyle(.gray)

            VStack(spacing: 6) {
                Text("No posts nearby.")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("There are no posts in your region right now.")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .fontWeight(.regular)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Button("Try Again") {
                retry()
            }
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .allowsHitTesting(true)
    }
}

//struct EmptyFeedView: View {
//    var retry: () -> Void
//
//    var body: some View {
//        ZStack {
////            EmptyFeedBackground()
//
//            EmptyFeedMessage(retry: retry)
//        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//    }
//}
//
//#Preview {
//    EmptyFeedView(retry: {})
//}
