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
    
    let refresh: () -> ()
    
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
                        if newPostVM.selectedPostLocationVisibilty == .visible {
                            newPostVM.isShareLocationAlertDisplayed = true
                        } else {
                            Task {
                                try await postNewPublication()
                            }
                        }
                    }) {
                        Text("Post", comment: "Action")
                    }
                    .disabled(newPostVM.postText.isEmpty)
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
            
            Text(authVM.username)
                .fontWeight(.semibold)
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
    
    //MARK: - Footer
    
    @ViewBuilder
    private func Footer() -> some View {
        VStack(alignment: .leading) {
            ImagePreview()
            
            VStack {
                Divider()
                
                HStack {
                    HStack(spacing: 16) {
                        Location()
                        
                        Tag()
                        
                        Duration()
                        
                        Picture()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    
                    Text("\(newPostVM.postText.count)/\(maxPostLength)")
                        .foregroundStyle(.gray)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                }
            }
            .frame(height: 32)
        }
    }
    
    //MARK: - Location
    
    @ViewBuilder
    private func Location() -> some View {
        Menu {
            ForEach(PostLocationVisibility.allCases, id: \.self) { visibility in
                Button {
                    newPostVM.selectedPostLocationVisibilty = visibility
                } label: {
                    Image(systemName: visibility.imageName)
                    Text(visibility.title)
                }
            }
        } label: {
            HStack(spacing: 0) {
                Image(systemName: newPostVM.selectedPostLocationVisibilty.imageName)
                Image(systemName: "chevron.up.chevron.down")
                    .scaleEffect(0.8)
            }
        }
    }
    
    //MARK: - Tag
    
    @ViewBuilder
    private func Tag() -> some View {
        Menu {
            ForEach(PostTag.allCases, id: \.self) { tag in
                Button {
                    newPostVM.selectedPostTag = tag
                } label: {
                    Image(systemName: tag.iconName)
                    Text(tag.title)
                }
            }
        } label: {
            HStack(spacing: 0) {
                Image(systemName: newPostVM.selectedPostTag.iconName)
                Image(systemName: "chevron.up.chevron.down")
                    .scaleEffect(0.8)
            }
        }
    }
    
    //MARK: - Duration
    
    @ViewBuilder
    private func Duration() -> some View {
        Menu {
            ForEach(PostDuration.allCases, id: \.self) { duration in
                Button {
                    newPostVM.selectedPostDuration = duration
                } label: {
                    Text(duration.title)
                }
            }
            Text("Post will stay active for:")
        } label: {
            HStack(spacing: 0) {
                HStack {
                    Image(systemName: "clock")
                    Text(newPostVM.selectedPostDuration.abbreviatedTitle)
                }
                Image(systemName: "chevron.up.chevron.down")
                    .scaleEffect(0.8)
            }
        }
    }
    
    //MARK: - Picture
    
    @ViewBuilder
    private func Picture() -> some View {
        Button {
            newPostVM.isCameraDisplayed = true
        } label: {
            Image(systemName:  "camera")
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
                refresh()
            }
        } else {
            newPostVM.overlayError = (true, ErrorMessage.locationDisabledErrorMessage)
        }
    }
}

#Preview {
    NewPostScreen(refresh: {})
        .environmentObject(AuthenticationViewModel())
}
