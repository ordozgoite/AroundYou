//
//  UserProfileScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 15/02/24.
//

import SwiftUI

struct UserProfileScreen: View {
    
    let userUid: String
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @StateObject private var userProfileVM = UserProfileViewModel()
    @ObservedObject var socket: SocketService
    @Environment(\.presentationMode) var presentationMode
    @Namespace private var profileAnimation
    
    var body: some View {
        ZStack {
            VStack {
                if userProfileVM.isLoading {
                    ProgressView()
                } else {
                    VStack {
                        VStack {
                            ProfileHeader()
                        }
                        .frame(maxHeight: .infinity, alignment: .top)
                        
                        Warning()
                            .frame(maxHeight: .infinity, alignment: .top)
                    }
                }
            }
            
            FullScreenPicture()
            
            AYErrorAlert(message: userProfileVM.overlayError.1 , isErrorAlertPresented: $userProfileVM.overlayError.0)
            
            NavigationLink(
                destination: ReportScreen(reportedUserUid: userUid, publicationId: nil, commentId: nil).environmentObject(authVM),
                isActive: $userProfileVM.isReportScreenPresented,
                label: { EmptyView() }
            )
            
            NavigationLink(
                destination: MessageScreen(chatId: userProfileVM.isMessageScreenPresented.1, username: userProfileVM.userProfile?.username ?? "", otherUserUid: userProfileVM.userProfile?.userUid ?? "", chatPic: userProfileVM.userProfile?.profilePic, socket: socket).environmentObject(authVM),
                isActive: $userProfileVM.isMessageScreenPresented.0,
                label: { EmptyView() }
            )
        }
        .onAppear {
            Task {
                let token = try await authVM.getFirebaseToken()
                await userProfileVM.getUserProfile(userUid: userUid, token: token)
            }
        }
        .alert(isPresented: $userProfileVM.isBlockAlertPresented) {
            Alert(
                title: Text("Block User"),
                message: Text("This user will not be able to see your posts and profile, and you will not be able to see this user's posts and profile."),
                primaryButton: .destructive(Text("Block")) {
                    Task {
                        let token = try await authVM.getFirebaseToken()
                        await userProfileVM.blockUser(blockedUserUid: userUid, token: token) {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                },
                secondaryButton: .cancel(Text("Cancel")) {}
            )
        }
        .toolbar {
            ToolbarItem {
                if let myId = authVM.user?.uid {
                    if self.userUid != myId {
                        Menu {
                            Button {
                                userProfileVM.isReportScreenPresented = true
                            } label: {
                                Text("Report Account")
                                Image(systemName: "exclamationmark.bubble")
                            }
                            
                            Button {
                                userProfileVM.isBlockAlertPresented = true
                            } label: {
                                Text("Block User")
                                Image(systemName: "person.fill.xmark")
                            }
                            
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    //MARK: - Profile Header
    
    @ViewBuilder
    private func ProfileHeader() -> some View {
        VStack(spacing: 16) {
            if !userProfileVM.isProfilePicFullScreen {
                ProfilePic
                    .matchedGeometryEffect(id: "Image", in: profileAnimation)
                    .frame(width: 128, height: 128)
            }
            
            VStack(spacing: 16) {
                VStack {
                    Text(userProfileVM.userProfile?.name ?? "")
                        .font(.title)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    Text("@" + (userProfileVM.userProfile?.username ?? ""))
                        .foregroundStyle(.gray)
                        .fontWeight(.semibold)
                        .font(.subheadline)
                }
                
                Text(userProfileVM.userProfile?.biography ?? "")
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                
                if let myId = authVM.user?.uid {
                    if userUid != myId {
                        Button {
                            Task {
                                let token = try await authVM.getFirebaseToken()
                                await userProfileVM.postNewChat(otherUserUid: self.userUid, token: token)
                            }
                        } label: {
                            Image(systemName: "bubble.left")
                            Text("Message")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
        .padding()
    }
    
    //MARK: - Warning
    
    @ViewBuilder
    private func Warning() -> some View {
        if let myId = authVM.user?.uid {
            if userUid == myId {
                Text("That's how people see you.")
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .fontWeight(.semibold)
                    .padding()
            } else {
                Text("You can't see other people's post history.")
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .fontWeight(.semibold)
                    .padding()
            }
        }
    }
    
    //MARK: - FullScreen Picture
    
    @ViewBuilder
    private func FullScreenPicture() -> some View {
        if userProfileVM.isProfilePicFullScreen {
            ProfilePic
                .matchedGeometryEffect(id: "Image", in: profileAnimation)
                .frame(width: screenWidth - 32, height: screenWidth - 32)
                .frame(width: screenWidth, height: screenHeight)
                .background(.thinMaterial)
                .ignoresSafeArea()
        }
    }
    
    //MARK: - Profile Pic
    
    private var ProfilePic: some View {
        VStack {
            if let imageURL = userProfileVM.userProfile?.profilePic {
                URLImageView(imageURL: imageURL)
                    .aspectRatio(contentMode: .fill)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundStyle(.gray)
                    .aspectRatio(contentMode: .fill)
            }
        }
        .onTapGesture {
            withAnimation(.spring()) {
                userProfileVM.isProfilePicFullScreen.toggle()
            }
        }
    }
}
