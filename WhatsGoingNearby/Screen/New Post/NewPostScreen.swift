//
//  NewPostScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import SwiftUI

struct NewPostScreen: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var newPostVM = NewPostViewModel()
    @ObservedObject var locationManager = LocationManager()
    @Environment(\.presentationMode) var presentationMode
    
    let refresh: () -> ()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            PreferenceView()
            
            TextField("What's going on around you?", text: $newPostVM.postText, axis: .vertical)
            
            Spacer()
        }
        .padding()
        
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
                        Task {
                            try await postNewPublication()
                        }
                    }) {
                        Text("Post")
                    }
                    .disabled(newPostVM.postText.isEmpty)
                }
            }
        }
        .navigationTitle("Create new post")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    //MARK: - Preference
    
    @ViewBuilder
    private func PreferenceView() -> some View {
        HStack {
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
            
            Text(authVM.name)
                .fontWeight(.semibold)
        }
    }
    
    //MARK: - Auxiliary Methods
    
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
        }
    }
}

#Preview {
    NewPostScreen(refresh: {})
        .environmentObject(AuthenticationViewModel())
}
