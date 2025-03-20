//
//  HomeScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 20/03/25.
//

import SwiftUI

struct HomeScreen: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var socket: SocketService
    
    @State private var selectedSection: HomeSection = .posts

    var body: some View {
        VStack {
            Picker("Seção", selection: $selectedSection) {
                ForEach(HomeSection.allCases, id: \.self) { section in
                    Text(section.rawValue).tag(section)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            Spacer()

            switch selectedSection {
            case .posts:
                FeedScreen(locationManager: locationManager, socket: socket)
                    .environmentObject(authVM)
            case .discover:
                DiscoverScreen(locationManager: locationManager, socket: socket)
                    .environmentObject(authVM)
            case .business:
                BusinessScreen(locationManager: locationManager)
                    .environmentObject(authVM)
            case .urgent:
                Text("UrgentScreen")
            case .communities:
                CommunityListScreen(locationManager: locationManager, socket: socket)
                    .environmentObject(authVM)
            }
            
            Spacer()
        }
    }
}

#Preview {
    HomeScreen(locationManager: LocationManager(), socket: SocketService())
}
