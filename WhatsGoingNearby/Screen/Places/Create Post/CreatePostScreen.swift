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
    @EnvironmentObject var placesVM: PlacesViewModel
    @StateObject private var createPostVM = CreatePostViewModel()
    
    var body: some View {
        ZStack {
            ComposePost()
            
            AYErrorAlert(message: createPostVM.overlayError.1 , isErrorAlertPresented: $createPostVM.overlayError.0)
        }
        .fullScreenCover(isPresented: $createPostVM.isMediaPickerDisplayed) {
            MediaPickerView(
                mediaKind: createPostVM.mediaPickerKind,
                onImageSelected: createPostVM.selectImage,
                onVideoSelected: createPostVM.selectVideo,
                onDismiss: { createPostVM.isMediaPickerDisplayed = false }
            )
            .ignoresSafeArea()
        }
        .alert(isPresented: $createPostVM.isShareLocationAlertDisplayed) {
            Alert(
                title: Text("Allow 'AroundYou' to display your location on map?"),
                message: Text("Your precise location will be used to display on the map where you made this post."),
                primaryButton: .default((Text("Allow Once"))) {
                    Task {
                        queuePost()
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
            tag: $createPostVM.selectedPostTag,
            selectedVideo: $createPostVM.selectedVideo,
            isProcessingVideo: createPostVM.isProcessingVideo,
            onCaptureMedia: { kind in
                Task { await createPostVM.presentCamera(kind: kind) }
            },
            onRemoveVideo: createPostVM.removeSelectedVideo
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
                    queuePost()
                }
            }
        } label: {
            Text("Post", comment: "Action")
        }
        .disabled((createPostVM.postText.isEmpty && createPostVM.image == nil && createPostVM.selectedVideo == nil) || createPostVM.isProcessingVideo)
    }
    
    //MARK: - Private Methods
    
    private func queuePost() {
        let postToBePublished = PendingPost(
            text: createPostVM.postText,
            tag: createPostVM.selectedPostTag,
            image: createPostVM.image,
            video: createPostVM.selectedVideo,
            isLocationVisible: createPostVM.isLocationVisible
        )
        placesVM.postToBePublished = postToBePublished
        navCoordinator.goBack()
    }
}

#Preview {
    CreatePostScreen()
        .environmentObject(AuthenticationViewModel())
        .environmentObject(LocationManager())
        .environmentObject(NavigationCoordinator())
}
