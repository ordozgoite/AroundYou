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
    @State private var isLoading: Bool = false
    let refresh: () -> ()
    
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
                Text(authVM.name)
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
