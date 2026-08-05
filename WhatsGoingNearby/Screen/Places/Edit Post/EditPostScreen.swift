//
//  EditPostScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 02/04/24.
//

import SwiftUI
import CoreLocation

struct EditPostScreen: View {
    var post: FormattedPost
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var navCoordinator: NavigationCoordinator
    @StateObject private var editPostVM = EditPostViewModel()
    
    var body: some View {
        ZStack {
            ComposePost()
            
            AYErrorAlert(message: editPostVM.overlayError.1 , isErrorAlertPresented: $editPostVM.overlayError.0)
        }
        .alert(isPresented: $editPostVM.isShareLocationAlertDisplayed) {
            Alert(
                title: Text("Allow 'AroundYou' to display your location on map?"),
                message: Text("Your precise location will be used to display on the map where you made this post."),
                primaryButton: .default((Text("Allow Once"))) {
                    Task {
                        try await handlePublicationEdit()
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
                if editPostVM.isLoading {
                    ProgressView()
                } else {
                    Done()
                }
            }
        }
        .onAppear {
            setupInitialValues()
        }
        .navigationTitle("Edit post")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    //MARK: - Compose Post
    
    @ViewBuilder
    private func ComposePost() -> some View {
        ComposePostView(
            maxLength: Constants.MAX_POST_LENGHT,
            isCameraEnabled: false,
            text: $editPostVM.postText,
            isLocationVisible: $editPostVM.isLocationVisible,
            isSettingsExpanded: $editPostVM.isSettingsExpanded,
            image: .constant(nil),
            isCameraDisplayed: .constant(false),
            tag: $editPostVM.selectedPostTag,
            selectedVideo: .constant(nil),
            isProcessingVideo: false,
            onSelectMedia: { _, _ in },
            onRemoveVideo: {}
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
    
    //MARK: - Done
    
    @ViewBuilder
    private func Done() -> some View {
        Button {
            if editPostVM.isLocationVisible {
                editPostVM.isShareLocationAlertDisplayed = true
            } else {
                Task {
                    try await handlePublicationEdit()
                }
            }
        } label: {
            Text("Done")
        }
    }
    
    //MARK: - Private Methods
    
    private func setupInitialValues() {
        editPostVM.postText = post.text ?? ""
        editPostVM.isLocationVisible = post.isLocationVisible ?? false
        editPostVM.selectedPostTag = post.postTag ?? .chilling
    }
    
    private func handlePublicationEdit() async throws {
        do {
            try await attemptPublicationEdit()
        } catch {
            editPostVM.overlayError = (true, ErrorMessage.editPostErrorMessage)
        }
    }
    
    private func attemptPublicationEdit() async throws {
        let currentLocation = try getCurrentLocation()
        let token = try await authVM.getFirebaseToken()
        try await editPostVM.editPublication(publicationId: post.id, latitude: currentLocation.latitude, longitude: currentLocation.longitude, token: token)
        navCoordinator.goToRoot()
    }
    
    private func getCurrentLocation() throws -> Location {
        locationManager.requestLocation()
        if let location = locationManager.location {
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            return Location(latitude: latitude, longitude: longitude)
        } else {
            editPostVM.overlayError = (true, ErrorMessage.locationDisabledErrorMessage)
            throw LocationError.unableToGetCurrentLocation
        }
    }
    
    private func refreshFeed() {
        NotificationCenter.default.post(name: .refreshLocationSensitiveData, object: nil)
    }
}

//#Preview {
//    EditPostScreen()
//}
