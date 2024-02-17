//
//  ProfileScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import SwiftUI

@MainActor
struct AccountScreen: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @ObservedObject private var accountVM = AccountViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    ProfileHeader()
                    
                    History()
                }
            }
            .onAppear {
                Task {
                    let token = try await authVM.getFirebaseToken()
                    await accountVM.getUserPosts(token: token)
                }
            }
            .toolbar {
                ToolbarItem {
                    NavigationLink {
                        SettingsScreen()
                            .environmentObject(authVM)
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
        }
    }
    
    //MARK: - Profile Header
    
    @ViewBuilder
    private func ProfileHeader() -> some View {
        VStack(spacing: 16) {
            if let imageURL = authVM.profilePic {
                URLImageView(imageURL: imageURL)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 128, height: 128)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 128, height: 128)
            }
            
            VStack {
                Text(authVM.name)
                    .font(.title)
                    .fontWeight(.semibold)
                
                ZStack(alignment: .topTrailing) {
                    Text(authVM.biography ?? "No bio")
                        .foregroundStyle(.gray)
                    
                    Image(systemName: "pencil.circle")
                        .foregroundStyle(.gray)
                        .offset(x: 32)
                        .onTapGesture {
                            accountVM.isEditBioAlertPresented = true
                        }
                }
                .alert("Edit your biography.", isPresented: $accountVM.isEditBioAlertPresented) {
                    TextField("Enter your bio", text: $accountVM.newBioTextInput)
                    Button("Cancel", role: .cancel) { }
                    Button("Edit") {
                        Task {
                            let token = try await authVM.getFirebaseToken()
                            await accountVM.editBio(bio: accountVM.newBioTextInput, token: token) { bio in
                                authVM.biography = bio
                            }
                        }
                    }
                } message: {
                    Text("Your biography can be seen by anyone who visits your profile.")
                }
            }
        }
    }
    
    //MARK: - History
    
    @ViewBuilder
    private func History() -> some View {
        VStack {
            PostTypeSegmentedControl(selectedFilter: $accountVM.selectedPostType)
            
            PostsView()
        }
    }
    
    //MARK: - Posts View
    
    @ViewBuilder
    private func PostsView() -> some View {
        ScrollView {
            ForEach($accountVM.posts) { $post in
                if shouldDisplay(post: post) {
                    PostView(post: $post) {
                        Task {
                            let token = try await authVM.getFirebaseToken()
                            await accountVM.deletePublication(publicationId: post.id, token: token)
                        }
                    }
                    .padding()
                    Divider()
                }
            }
        }
    }
    
    //MARK: - Auxiliary Methods
    
    private func shouldDisplay(post: FormattedPost) -> Bool {
        switch accountVM.selectedPostType {
        case .all:
            return true
        case .active:
            return post.type == .active
        case .inactive:
            return post.type == .inactive
        }
    }
}

#Preview {
    AccountScreen()
        .environmentObject(AuthenticationViewModel())
}
