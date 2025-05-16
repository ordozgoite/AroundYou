//
//  DiscoverView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 27/10/24.
//

import SwiftUI

struct DiscoverView: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @ObservedObject var discoverVM: PeopleViewModel
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var socket: SocketService
    
    @State private var refreshObserver = NotificationCenter.default
        .publisher(for: .refreshLocationSensitiveData)
    
    var body: some View {
        NavigationStack {
            ZStack {
                if discoverVM.isDiscoveringUsers {
                    LoadingView()
                } else if discoverVM.usersFound.isEmpty {
                    EmptyDiscoverView()
                } else {
                    Users()
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
//            .navigationTitle("Discover")
        }
        .onReceive(refreshObserver) { _ in
            Task {
                try await getUsersNearBy()
            }
        }
        .onAppear {
            startUpdatingUsers()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    //MARK: - Loading
    
    @ViewBuilder
    private func LoadingView() -> some View {
        VStack {
            AYProgressView()
            
            Text("Looking around you...")
                .foregroundStyle(.gray)
                .fontWeight(.semibold)
        }
        .frame(maxHeight: .infinity, alignment: .center)
    }
    
    // MARK: - Users
    
    @ViewBuilder
    private func Users() -> some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(discoverVM.usersFound) { user in
                    ZStack {
                        DiscoverUserView(
                            userImageURL: user.profilePic,
                            userName: user.username,
                            gender: user.genderEnum,
                            age: user.age,
                            lastSeen: user.locationLastUpdateAt
                        )
                        .onTapGesture {
                            Task {
                                try await postNewChat(withUser: user)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .refreshable {
            hapticFeedback(style: .soft)
            Task {
                try await getUsersNearBy()
            }
        }
        .navigationDestination(isPresented: $discoverVM.isMessageScreenDisplayed) {
            if let chatUser = discoverVM.chatUser {
                MessageScreen(
                    chatId: chatUser._id,
                    username: discoverVM.userToChatWith?.username ?? "",
                    otherUserUid: discoverVM.userToChatWith?.userUid ?? "",
                    chatPic: discoverVM.userToChatWith?.profilePic,
                    isLocked: chatUser.isLocked,
                    socket: socket
                )
            }
        }
    }

    
    //MARK: - Private Method
    
    private func startUpdatingUsers() {
        discoverVM.discoverTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task {
                try await getUsersNearBy()
            }
        }
        discoverVM.discoverTimer?.fire()
    }
    
    private func getUsersNearBy() async throws {
        locationManager.requestLocation()
        if let location = locationManager.location {
            let token = try await authVM.getFirebaseToken()
            
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            
            await discoverVM.getUsersNearBy(latitude: latitude, longitude: longitude, token: token)
        }
    }
    
    private func stopTimer() {
        discoverVM.discoverTimer?.invalidate()
    }
    
    private func postNewChat(withUser user: UserDiscoverInfo) async throws {
        discoverVM.userToChatWith = user
        let token = try await authVM.getFirebaseToken()
        await discoverVM.postNewChat(otherUserUid: user.userUid, token: token)
    }
}

#Preview {
    //    DiscoverView(discoverVM: DiscoverViewModel())
    //        .environmentObject(AuthenticationViewModel())
}
