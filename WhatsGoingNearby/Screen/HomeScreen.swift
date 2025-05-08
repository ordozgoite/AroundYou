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
    
    /*
     Os ViewModels são instanciados nesta tela parent em vez de dentro de suas respectivas Views. Isso garante a persistência do estado de cada View ao navegar para fora e voltar, utilizando o AYFeatureSelector.
    */
    @StateObject private var placesVM = PlacesViewModel()
    @StateObject private var discoverVM = DiscoverViewModel()
    @StateObject private var businessVM = BusinessViewModel()
    @StateObject private var communityVM = CommunityViewModel()
    
    @State private var selectedSection: HomeSection = .places

    var body: some View {
        NavigationStack {
            VStack {
                AYFeatureSelector(selectedSection: $selectedSection)
                
                switch selectedSection {
                case .places:
                    PlacesScreen(placesVM: placesVM, locationManager: locationManager, socket: socket)
                        .environmentObject(authVM)
                case .discover:
                    DiscoverScreen(discoverVM: discoverVM, locationManager: locationManager, socket: socket)
                        .environmentObject(authVM)
                case .business:
                    BusinessScreen(businessVM: businessVM, locationManager: locationManager)
                        .environmentObject(authVM)
                case .communities:
                    CommunityListScreen(communityVM: communityVM, locationManager: locationManager, socket: socket)
                        .environmentObject(authVM)
                }
                
                Spacer()
            }
        }
    }
}

#Preview {
    HomeScreen(locationManager: LocationManager(), socket: SocketService())
}
