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
    
    let refresh: () -> ()
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 32) {
                Header()
                
                TextField("What's going on around you?", text: $newPostVM.postText, axis: .vertical)
                    .onChange(of: newPostVM.postText) { newValue in
                        if newValue.count > maxPostLength {
                            newPostVM.postText = String(newValue.prefix(maxPostLength))
                        }
                    }
                
                Spacer()
            }
            .padding()
            
            if newPostVM.overlayError.0 {
                AYErrorAlert(message: newPostVM.overlayError.1 , isErrorAlertPresented: $newPostVM.overlayError.0)
            }
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
    
    //MARK: - Header
    
    @ViewBuilder
    private func Header() -> some View {
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
            
            VStack(alignment: .leading) {
                Text(authVM.name)
                    .fontWeight(.semibold)
                
                Text("\(newPostVM.postText.count)/\(maxPostLength)")
                    .foregroundStyle(.gray)
                    .font(.subheadline)
            }
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
