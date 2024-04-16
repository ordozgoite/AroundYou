//
//  NewPostScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import SwiftUI

struct NewPostScreen: View {
    
    private let maxPostLength = 250
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var newPostVM = NewPostViewModel()
    @ObservedObject var locationManager = LocationManager()
    @Environment(\.presentationMode) var presentationMode
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 32) {
                Header()
                
                TextField("What's going on around you?", text: $newPostVM.postText, axis: .vertical)
                    .focused($isFocused)
                    .onChange(of: newPostVM.postText) { newValue in
                        if newValue.count > maxPostLength {
                            newPostVM.postText = String(newValue.prefix(maxPostLength))
                        }
                    }
                
                Spacer()
                
                Footer()
            }
            .padding()
            
            AYErrorAlert(message: newPostVM.overlayError.1 , isErrorAlertPresented: $newPostVM.overlayError.0)
        }
        .fullScreenCover(isPresented: $newPostVM.isCameraDisplayed) {
            CameraView(image: $newPostVM.image)
        }
        .alert(isPresented: $newPostVM.isShareLocationAlertDisplayed) {
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
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Cancel")
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                if newPostVM.isLoading {
                    ProgressView()
                } else {
                    Button(action: {
                        if newPostVM.isLocationVisible {
                            newPostVM.isShareLocationAlertDisplayed = true
                        } else {
                            Task {
                                try await postNewPublication()
                            }
                        }
                    }) {
                        Text("Post", comment: "Action")
                    }
                    .disabled(newPostVM.postText.isEmpty && newPostVM.image == nil)
                }
            }
        }
        .onAppear {
            self.isFocused = true
        }
        .navigationTitle("Create new post")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    //MARK: - Header
    
    @ViewBuilder
    private func Header() -> some View {
        HStack {
            ProfilePic()
            
            VStack(alignment: .leading) {
                Text(authVM.username)
                    .fontWeight(.semibold)
                
                Location()
            }
        }
    }
    
    //MARK: - Profile Pic
    
    @ViewBuilder
    private func ProfilePic() -> some View {
        if let imageURL = authVM.profilePic {
            URLImageView(imageURL: imageURL)
                .aspectRatio(contentMode: .fill)
                .frame(width: 50, height: 50)
                .clipShape(Circle())
        } else {
            Image(systemName: "person.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 50, height: 50)
        }
    }
    
    //MARK: - Location
    
    @ViewBuilder
    private func Location() -> some View {
        if newPostVM.isLocationVisible {
            Button {
                withAnimation {
                    newPostVM.isLocationVisible.toggle()
                }
                
            } label: {
                Label(
                    title: { Text("Show me on map") },
                    icon: { Image(systemName: "map") }
                )
            }
            .buttonStyle(.borderedProminent)
        } else {
            Button {
                withAnimation {
                    newPostVM.isLocationVisible.toggle()
                }
            } label: {
                Label(
                    title: { Text("Don't show me on map") },
                    icon: { Image(systemName: "mappin.slash") }
                )
            }
            .buttonStyle(.bordered)
        }
    }
    
    //MARK: - Footer
    
    @ViewBuilder
    private func Footer() -> some View {
        VStack(spacing: 0) {
            HStack {
                ImagePreview()
                
                Spacer()
                
                Camera()
            }
            .padding(.bottom)
            
            Chevron()
            
            if newPostVM.isSettingsExpanded {
                ExpandedPostSettings(newPostVM: newPostVM, isExpanded: $newPostVM.isSettingsExpanded)
            } else {
                CompactedPostSettings(newPostVM: newPostVM, isExpanded: $newPostVM.isSettingsExpanded)
            }
        }
    }
    
    //MARK: - Image Preview
    
    @ViewBuilder
    private func ImagePreview() -> some View {
        if let selectedImage =  newPostVM.image {
            ZStack(alignment: .topTrailing) {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 64)
                    .cornerRadius(8)
                    .padding()
                
                Button {
                    newPostVM.image = nil
                } label: {
                    Image(systemName: "x.circle.fill")
                }
            }
        }
    }
    
    //MARK: - Camera
    
    @ViewBuilder
    private func Camera() -> some View {
        Image(systemName: "camera.circle.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 44, height: 44, alignment: .center)
            .foregroundStyle(.blue)
            .background(
                Circle()
                    .frame(width: 44, height: 44, alignment: .center)
                    .foregroundStyle(.white)
                    .shadow(color: Color.black.opacity(0.5), radius: 5, x: 1, y: 1)
            )
            .onTapGesture {
                newPostVM.isCameraDisplayed = true
            }
        
    }
    
    //MARK: - Chevron
    
    @ViewBuilder
    private func Chevron() -> some View {
        Image(systemName: newPostVM.isSettingsExpanded ? "chevron.compact.down" : "chevron.compact.up")
            .resizable()
            .foregroundStyle(.gray)
            .scaledToFit()
            .frame(width: 32, height: 12)
            .onTapGesture {
                withAnimation {
                    newPostVM.isSettingsExpanded.toggle()
                }
            }
    }
    
    //MARK: - Private Methods
    
    private func postNewPublication() async throws {
        locationManager.requestLocation()
        if let location = locationManager.location {
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            
            let token = try await authVM.getFirebaseToken()
            await newPostVM.postNewPublication(latitude: latitude, longitude: longitude, token: token) {
                presentationMode.wrappedValue.dismiss()
                refreshFeed()
            }
        } else {
            newPostVM.overlayError = (true, ErrorMessage.locationDisabledErrorMessage)
        }
    }
    
    private func refreshFeed() {
        let name = Notification.Name(Constants.refreshFeedNotificationKey)
        NotificationCenter.default.post(name: name, object: nil)
    }
}

#Preview {
    NewPostScreen()
        .environmentObject(AuthenticationViewModel())
}
