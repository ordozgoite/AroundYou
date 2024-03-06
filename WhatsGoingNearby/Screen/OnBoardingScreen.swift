//
//  OnBoardingScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 24/02/24.
//

import SwiftUI

struct OnBoardingScreen: View {
    
    @Binding var hasCompletedOnboarding: Bool
    
    var body: some View {
        NavigationStack {
            TabView {
                Location()
                
                Time()
                
                UseCase()
            }
            .tabViewStyle(PageTabViewStyle())
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            .toolbar {
                ToolbarItem {
                    Button("OK") {
                        hasCompletedOnboarding = true
                        LocalState.hasCompletedOnboarding = true
                    }
                }
            }
        }
    }
    
    //MARK: - Location
    
    @ViewBuilder
    private func Location() -> some View {
        ZStack {
            LottieView(name: "meet", loopMode: .loop)
                .frame(width: screenWidth - 64, height: 256)
                .padding(32)
                .scaleEffect(0.8)
                .offset(y: -50)
            
            VStack(alignment: .leading, spacing: 32) {
                Spacer()
                
                HStack {
                    Text("Location 📍")
                        .font(.title)
                        .fontWeight(.black)
                    
                    Spacer()
                }
                
                Text("AroundYou uses your location, displaying posts exclusively to those within a **1km radius**, ensuring you connect with nearby people and events.")
                    .fontWeight(.light)
                    .multilineTextAlignment(.leading)
            }
            .frame(width: screenWidth - 32)
            .padding(.bottom, 64)
        }
        .padding()
    }
    
    //MARK: - Time
    
    @ViewBuilder
    private func Time() -> some View {
        ZStack {
            TimerAnimation()
                .offset(y: -50)
            
            VStack(alignment: .leading, spacing: 32) {
                Spacer()
                
                HStack {
                    Text("Temporary posts ⏳")
                        .font(.title)
                        .fontWeight(.black)
                    
                    Spacer()
                }
                Text("Posts on AroundYou remain active for just **8 hours**, ensuring you discover timely and relevant information effortlessly.")
                    .multilineTextAlignment(.leading)
            }
            .frame(width: screenWidth - 32)
            .padding(.bottom, 64)
        }
        .padding()
    }
    
    //MARK: - UseCase
    
    @ViewBuilder
    private func UseCase() -> some View {
        ZStack {
            LottieView(name: "party", loopMode: .loop)
                .frame(width: screenWidth - 64, height: 256)
                .padding(32)
                .scaleEffect(0.6)
                .offset(y: -50)
            
            VStack(alignment: .leading, spacing: 32) {
                Spacer()
                
                HStack {
                    Text("Interact with people 🌐")
                        .font(.title)
                        .fontWeight(.black)
                    
                    Spacer()
                }
                
                Text("Discover endless possibilities with AroundYou! Meet new people, seek local information, and explore nearby events—all at your fingertips.")
                    .fontWeight(.light)
                    .multilineTextAlignment(.leading)
            }
            .frame(width: screenWidth - 32)
            .padding(.bottom, 64)
        }
        .padding()
    }
}

#Preview {
    OnBoardingScreen(hasCompletedOnboarding: .constant(true))
}
