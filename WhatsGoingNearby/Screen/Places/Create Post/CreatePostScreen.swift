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
    @State private var isCheckingPublicationEligibility = false
    @State private var isPublicationLimitAlertDisplayed = false
    @State private var isReplacePublicationConfirmationDisplayed = false
    @State private var isReplacingActivePublication = false
    
    var body: some View {
        ZStack {
            ComposePost()
            
            AYErrorAlert(message: createPostVM.overlayError.1 , isErrorAlertPresented: $createPostVM.overlayError.0)
        }
        .safeAreaInset(edge: .top) {
            if isCheckingPublicationEligibility || isReplacingActivePublication {
                HStack(spacing: 8) {
                    ProgressView()
                    Text(isReplacingActivePublication ? "Ending active publication..." : "Checking whether you can publish...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }
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
        .sheet(isPresented: $createPostVM.isLibraryPickerDisplayed) {
            PhotoPicker(selectedPhoto: Binding(
                get: { createPostVM.image },
                set: { selectedImage in
                    guard let selectedImage else { return }
                    createPostVM.selectImageFromLibrary(selectedImage)
                }
            ))
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
        .alert("Publication limit reached", isPresented: $isPublicationLimitAlertDisplayed) {
            if let publicationId = placesVM.publicationCreationEligibility?.activePublicationId {
                Button("View active publication") {
                    navCoordinator.setStack([.postDetail(publicationId)])
                }
                Button("End and continue", role: .destructive) {
                    isReplacePublicationConfirmationDisplayed = true
                }
            }
            Button("Keep editing", role: .cancel) {}
        } message: {
            Text(placesVM.publicationLimitMessage)
        }
        .confirmationDialog(
            "End active publication?",
            isPresented: $isReplacePublicationConfirmationDisplayed,
            titleVisibility: .visible
        ) {
            Button("End and continue", role: .destructive) {
                Task { await replaceActivePublication() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your current publication will stop appearing to nearby people.")
        }
        .navigationBarBackButtonHidden()
        .swipeToGoBack()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Cancel()
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                if createPostVM.isLoading || isCheckingPublicationEligibility || isReplacingActivePublication {
                    ProgressView()
                } else {
                    PostButton()
                }
            }
        }
        .navigationTitle("Create new post")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await verifyPublicationCreationEligibilityIfNeeded()
        }
    }
    
    //MARK: - Compose Post
    
    @ViewBuilder
    private func ComposePost() -> some View {
        ComposePostView(
            maxLength: Constants.MAX_POST_LENGHT,
            isCameraEnabled: !isCheckingPublicationEligibility && !isReplacingActivePublication && !placesVM.isPublicationLimitReached,
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
            onSelectFromLibrary: { createPostVM.isLibraryPickerDisplayed = true },
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
        .disabled(
            (createPostVM.postText.isEmpty && createPostVM.image == nil && createPostVM.selectedVideo == nil) ||
            createPostVM.isProcessingVideo ||
            isCheckingPublicationEligibility ||
            isReplacingActivePublication ||
            placesVM.isPublicationLimitReached
        )
    }
    
    //MARK: - Private Methods
    
    private func queuePost() {
        guard !placesVM.isPublicationLimitReached else {
            isPublicationLimitAlertDisplayed = true
            return
        }

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

    private func verifyPublicationCreationEligibilityIfNeeded() async {
        if placesVM.isPublicationEligibilityFresh {
            isPublicationLimitAlertDisplayed = placesVM.isPublicationLimitReached
            return
        }

        isCheckingPublicationEligibility = true
        defer { isCheckingPublicationEligibility = false }

        guard let token = try? await authVM.getFirebaseToken() else { return }
        guard let eligibility = await placesVM.refreshPublicationCreationEligibility(token: token) else { return }
        isPublicationLimitAlertDisplayed = eligibility.isLimitReached
    }

    private func replaceActivePublication() async {
        guard let publicationId = placesVM.publicationCreationEligibility?.activePublicationId else { return }

        isReplacingActivePublication = true
        defer { isReplacingActivePublication = false }

        do {
            let token = try await authVM.getFirebaseToken()
            if !(await placesVM.finishActivePublicationForReplacement(publicationId: publicationId, token: token)) {
                createPostVM.overlayError = (true, "The active publication could not be ended. Please try again.")
            }
        } catch {
            createPostVM.overlayError = (true, "The active publication could not be ended. Please try again.")
        }
    }
}

#Preview {
    CreatePostScreen()
        .environmentObject(AuthenticationViewModel())
        .environmentObject(LocationManager())
        .environmentObject(NavigationCoordinator())
}
