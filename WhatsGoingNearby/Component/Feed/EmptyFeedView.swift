//
//  EmptyFeedView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 16/02/24.
//

import SwiftUI

struct EmptyFeedView: View {
    @EnvironmentObject var authVM: AuthenticationViewModel
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var navCoordinator: NavigationCoordinator
    
    var retry: () -> ()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LottieView(name: "radar", loopMode: .loop)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .opacity(0.25)
                
                VStack(spacing: 16) {
                    Image(systemName: "location.magnifyingglass")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50)
                        .foregroundStyle(.gray)
                    
                    VStack {
                        Text("No posts found.")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("Be the first to make a post in your region...")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                            .fontWeight(.regular)
                            .multilineTextAlignment(.center)
                            .frame(width: screenWidth - 32)
                        
                        Button("Refresh") {
                            retry()
                        }
                    }
                }
                
//                VStack {
//                    NewPostView()
//                        .padding(.bottom, geometry.safeAreaInsets.bottom)
//                        .onTapGesture {
//                            navCoordinator.navigate(to: .createPost)
//                        }
//                    
//                }
//                .frame(maxHeight: .infinity, alignment: .top)
            }
        }
    }
}

#Preview {
    EmptyFeedView(retry: {})
        .environmentObject(AuthenticationViewModel())
}
