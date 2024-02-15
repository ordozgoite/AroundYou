//
//  NewPostScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import SwiftUI

struct NewPostScreen: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @ObservedObject var locationManager = LocationManager()
    @Environment(\.presentationMode) var presentationMode
    
    @State private var postText: String = ""
    @State private var isLoading: Bool = false
    let refresh: () -> ()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            PreferenceView()
            
            TextField("What's going on around you?", text: $postText, axis: .vertical)
            
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
                if isLoading {
                    ProgressView()
                } else {
                    Button(action: {
                        Task {
                            try await postNewPublication()
                        }
                    }) {
                        Text("Post")
                    }
                    .disabled(postText.isEmpty)
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
        if let location = locationManager.location {
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            isLoading = true
            let token = try await authVM.getFirebaseToken()
            let result = await AYServices.shared.postNewPublication(text: postText, latitude: latitude, longitude: longitude, token: token)
            isLoading = false
            
            switch result {
            case .success:
                presentationMode.wrappedValue.dismiss()
                refresh()
            case .failure(let error):
                // Display error
                print("❌ Error: \(error)")
            }
        }
    }
}

#Preview {
    NewPostScreen(refresh: {})
        .environmentObject(AuthenticationViewModel())
}
