//
//  EditPostScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 02/04/24.
//

import SwiftUI
import CoreLocation

struct EditPostScreen: View {
    
    let post: FormattedPost
    
    private let maxPostLength = 250
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var editPostVM = EditPostViewModel()
    @Binding var location: CLLocation?
    @Environment(\.presentationMode) var presentationMode
    @FocusState private var isFocused: Bool
    
    let refresh: () -> ()
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 32) {
                Header()
                
                TextField("What's going on around you?", text: $editPostVM.postText, axis: .vertical)
                    .focused($isFocused)
                    .onChange(of: editPostVM.postText) { newValue in
                        if newValue.count > maxPostLength {
                            editPostVM.postText = String(newValue.prefix(maxPostLength))
                        }
                    }
                
                Spacer()
                
                Footer()
            }
            .padding()
            
            AYErrorAlert(message: editPostVM.overlayError.1 , isErrorAlertPresented: $editPostVM.overlayError.0)
        }
        .alert(isPresented: $editPostVM.isShareLocationAlertDisplayed) {
            Alert(
                title: Text("Allow 'AroundYou' to display your location on map?"),
                message: Text("Your precise location will be used to display on the map where you made this post."),
                primaryButton: .default((Text("Allow Once"))) {
                    Task {
                        try await editPublication()
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
                if editPostVM.isLoading {
                    ProgressView()
                } else {
                    Button {
                        if editPostVM.selectedPostLocationVisibilty == .visible {
                            editPostVM.isShareLocationAlertDisplayed = true
                        } else {
                            Task {
                                try await editPublication()
                            }
                        }
                    } label: {
                        Text("Edit")
                    }
                    .disabled(editPostVM.postText.isEmpty)
                }
            }
        }
        .onAppear {
            setupInitialValues()
            self.isFocused = true
        }
        .navigationTitle("Edit post")
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
        if let url =  post.imageUrl {
            PostImageView(imageURL: url)
                .scaledToFit()
                .frame(height: 64)
                .cornerRadius(8)
                .padding()
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
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    
                    Text("\(editPostVM.postText.count)/\(maxPostLength)")
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
                    editPostVM.selectedPostLocationVisibilty = visibility
                } label: {
                    Image(systemName: visibility.imageName)
                    Text(visibility.title)
                }
            }
        } label: {
            HStack(spacing: 0) {
                Image(systemName: editPostVM.selectedPostLocationVisibilty.imageName)
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
                    editPostVM.selectedPostTag = tag
                } label: {
                    Image(systemName: tag.iconName)
                    Text(tag.title)
                }
            }
        } label: {
            HStack(spacing: 0) {
                Image(systemName: editPostVM.selectedPostTag.iconName)
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
                    editPostVM.selectedPostDuration = duration
                } label: {
                    Text(duration.title)
                }
            }
            Text("Post will stay active for:")
        } label: {
            HStack(spacing: 0) {
                HStack {
                    Image(systemName: "clock")
                    Text(editPostVM.selectedPostDuration.abbreviatedTitle)
                }
                Image(systemName: "chevron.up.chevron.down")
                    .scaleEffect(0.8)
            }
        }
    }
    
    //MARK: - Private Methods
    
    private func setupInitialValues() {
        editPostVM.postText = post.text
        editPostVM.selectedPostLocationVisibilty = post.isLocationVisible ? .visible : .hidden
        editPostVM.selectedPostDuration = post.postDuration
        editPostVM.selectedPostTag = post.postTag ?? .chat
    }
    
    private func editPublication() async throws {
        if let location = location {
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            
            let token = try await authVM.getFirebaseToken()
            await editPostVM.editPublication(publicationId: post.id, latitude: latitude, longitude: longitude, token: token) {
                presentationMode.wrappedValue.dismiss()
                refresh()
            }
        } else {
            editPostVM.overlayError = (true, ErrorMessage.locationDisabledErrorMessage)
        }
    }
}

//#Preview {
//    EditPostScreen()
//}
