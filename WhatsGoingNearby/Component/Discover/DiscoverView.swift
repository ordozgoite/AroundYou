//
//  DiscoverView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 27/10/24.
//

import SwiftUI

struct DiscoverView: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @ObservedObject var discoverVM: DiscoverViewModel
    @ObservedObject var locationManager: LocationManager
    
    var body: some View {
        NavigationStack {
            ZStack {
                if discoverVM.isDiscoveringUsers {
                    AYProgressView()
                } else if discoverVM.usersFound.isEmpty {
                    EmptyDiscoverView()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 32) {
                            ForEach(discoverVM.usersFound) { user in
                                DiscoverUserView(
                                    userImageURL: user.profilePic,
                                    userName: user.username,
                                    gender: user.genderEnum,
                                    age: user.age,
                                    lastSeen: user.locationLastUpdateAt
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            
            .onAppear {
                Task {
                    try await getUsersNearBy() // run again based on location change
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        discoverVM.isPreferencesViewDisplayed = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .navigationTitle("Discover")
        }
    }
    
    //MARK: - Private Method
    
    private func getUsersNearBy() async throws {
        locationManager.requestLocation()
        if let location = locationManager.location {
            let token = try await authVM.getFirebaseToken()
            
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            
            await discoverVM.getUsersNearBy(latitude: latitude, longitude: longitude, token: token)
        }
    }
}

struct BlurView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

#Preview {
//    DiscoverView(discoverVM: DiscoverViewModel())
//        .environmentObject(AuthenticationViewModel())
}
