//
//  NewPostScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import SwiftUI

struct NewPostScreen: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @ObservedObject private var newPostVM = NewPostViewModel()
    @ObservedObject var locationManager = LocationManager()
    @Environment(\.presentationMode) var presentationMode
    
    @State private var postText: String = ""
    
    var userName: String {
        switch newPostVM.selectedPostVisibility {
        case .identified:
            return "Victor Ordozgoite"
        case .anonymous:
            return "Anonymous"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            PreferenceView()
            
            TextField("What's going on around?", text: $postText, axis: .vertical)
            
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
        .navigationTitle("Create new post")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    //MARK: - Adjust
    
    @ViewBuilder
    private func PreferenceView() -> some View {
        HStack {
            switch newPostVM.selectedPostVisibility {
            case .identified:
                if let imageURL = authVM.profilePic {
                    ProfilePictureView(imageURL: imageURL)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                }
            case .anonymous:
                Image(systemName: "person.crop.circle.badge.questionmark.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
            }
            
            
            VStack {
                Text(userName)
                    .fontWeight(.semibold)
                
                Picker("", selection: $newPostVM.selectedPostVisibility) {
                    ForEach(PostVisibility.allCases, id: \.self) { category in
                        Text(category.title)
                            .tag(category)
                    }
                }
                .pickerStyle(.menu)
                .buttonStyle(.bordered)
            }
        }
    }
    
    //MARK: - Auxiliary Methods
    
    private func postNewPublication() async throws {
        if let location = locationManager.location {
            let token = try await authVM.getFirebaseToken()
            print("🔑 USER TOKEN: \(token)")
            
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            
            print("📍 Latitude: \(latitude)")
            print("📍 Longitude: \(longitude)")
            
            
            locationManager.requestLocation()
            await newPostVM.postNewPublication(text: self.postText, latitude: latitude, longitude: longitude, token: token) {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

#Preview {
    NewPostScreen()
        .environmentObject(AuthenticationViewModel())
}
