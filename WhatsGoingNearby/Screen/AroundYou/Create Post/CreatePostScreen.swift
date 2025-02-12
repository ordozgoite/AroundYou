//
//  NewPostScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import SwiftUI

struct CreatePostScreen: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var createPostVM = CreatePostViewModel()
    @ObservedObject var locationManager = LocationManager()
    @Environment(\.presentationMode) var presentationMode
    
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
                        try await postNewPublication()
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
            tag: $createPostVM.selectedPostTag,
            duration: $createPostVM.selectedPostDuration
        ).environmentObject(authVM)
    }
    
    //MARK: - Cancel
    
    @ViewBuilder
    private func Cancel() -> some View {
        Button {
            presentationMode.wrappedValue.dismiss()
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
                    try await postNewPublication()
                }
            }
        } label: {
            Text("Post", comment: "Action")
        }
        .disabled(createPostVM.postText.isEmpty && createPostVM.image == nil)
    }
    
    //MARK: - Private Methods
    
    private func postNewPublication() async throws {
        locationManager.requestLocation()
        if let location = locationManager.location {
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            
            let token = try await authVM.getFirebaseToken()
            await createPostVM.postNewPublication(latitude: latitude, longitude: longitude, token: token) {
                presentationMode.wrappedValue.dismiss()
                refreshFeed()
            }
        } else {
            createPostVM.overlayError = (true, ErrorMessage.locationDisabledErrorMessage)
        }
    }
    
    private func refreshFeed() {
        NotificationCenter.default.post(name: .refreshLocationSensitiveData, object: nil)
    }
}

#Preview {
    CreatePostScreen()
        .environmentObject(AuthenticationViewModel())
}
