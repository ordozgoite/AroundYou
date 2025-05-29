//
//  NewPostScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import SwiftUI

struct CreatePostScreen: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @EnvironmentObject var navCoordinator: NavigationCoordinator
    @EnvironmentObject var locationManager: LocationManager
    @StateObject private var createPostVM = CreatePostViewModel()
    
    var body: some View {
        ZStack {
            ComposePost()
            
            AYErrorAlert(message: createPostVM.overlayError.1 , isErrorAlertPresented: $createPostVM.overlayError.0)
        }
        .fullScreenCover(isPresented: $createPostVM.isCameraDisplayed) {
            CameraView { createPostVM.image = $0 }
        }
        .alert(isPresented: $createPostVM.isShareLocationAlertDisplayed) {
            Alert(
                title: Text("Allow 'AroundYou' to display your location on map?"),
                message: Text("Your precise location will be used to display on the map where you made this post."),
                primaryButton: .default((Text("Allow Once"))) {
                    Task {
                        try await handlePostCreation()
                    }
                },
                secondaryButton: .cancel(Text("Don't Allow")) {}
            )
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Cancel()
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                if createPostVM.isLoading {
                    ProgressView()
                } else {
                    PostButton()
                }
            }
        }
        .navigationTitle("Create new post")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    //MARK: - Compose Post
    
    @ViewBuilder
    private func ComposePost() -> some View {
        ComposePostView(
            maxLength: Constants.MAX_POST_LENGHT,
            isCameraEnabled: true,
            text: $createPostVM.postText,
            isLocationVisible: $createPostVM.isLocationVisible,
            isSettingsExpanded: $createPostVM.isSettingsExpanded,
            image: $createPostVM.image,
            isCameraDisplayed: $createPostVM.isCameraDisplayed,
            tag: $createPostVM.selectedPostTag
        ).environmentObject(authVM)
    }
    
    //MARK: - Cancel
    
    @ViewBuilder
    private func Cancel() -> some View {
        Button {
            navCoordinator.goBack()
        } label: {
            Text("Cancel")
        }
    }
    
    //MARK: - Post
    
    @ViewBuilder
    private func PostButton() -> some View {
        Button {
            if createPostVM.isLocationVisible {
                createPostVM.isShareLocationAlertDisplayed = true
            } else {
                Task {
                    try await handlePostCreation()
                }
            }
        } label: {
            Text("Post", comment: "Action")
        }
        .disabled(createPostVM.postText.isEmpty && createPostVM.image == nil)
    }
    
    //MARK: - Private Methods

    private func handlePostCreation() async throws {
        do {
            try await attemptPostCreation()
        } catch {
            print("❌ Error trying to create new post: \(error)")
        }
    }
    
    private func attemptPostCreation() async throws {
        let currentLocation = try getCurrentLocation()
        let token = try await authVM.getFirebaseToken()
        try await createPostVM.createNewPost(latitude: currentLocation.latitude, longitude: currentLocation.longitude, token: token)
        navCoordinator.goBack()
//            refreshFeed()
    }
    
    private func getCurrentLocation() throws -> Location {
        locationManager.requestLocation()
        if let location = locationManager.location {
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            return Location(latitude: latitude, longitude: longitude)
        } else {
            createPostVM.overlayError = (true, ErrorMessage.locationDisabledErrorMessage)
            throw LocationError.unableToGetCurrentLocation
        }
    }

    
    private func refreshFeed() {
        NotificationCenter.default.post(name: .refreshLocationSensitiveData, object: nil)
    }
}

#Preview {
    CreatePostScreen()
        .environmentObject(AuthenticationViewModel())
        .environmentObject(LocationManager())
        .environmentObject(NavigationCoordinator())
}
