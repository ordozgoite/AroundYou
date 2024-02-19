//
//  PostView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import SwiftUI

struct PostView: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @Binding var post: FormattedPost
    @State private var isTimeLeftPopoverDisplayed: Bool = false
    @State private var isOptionsPopoverDisplayed: Bool = false
    @State private var isReportScreenPresented: Bool = false
    @State private var isMapScreenPresented: Bool = false
    let deletePost: () -> ()
    
    var body: some View {
        VStack {
            HStack(alignment: .top, spacing: 8) {
                ProfilePic()
                
                VStack(alignment: .leading, spacing: 16) {
                    HeaderView()
                    
                    TextView()
                    
//                    if post.isLocationVisible {
//                        Location()
//                    }
                    
                    InteractionsView()
                }
            }
            NavigationLink(
                destination: ReportScreen(reportedUserUid: post.userUid, publicationId: post.id, commentId: nil).environmentObject(authVM),
                isActive: $isReportScreenPresented,
                label: { EmptyView() }
            )
            
            NavigationLink(
                destination: MapScreen(latitude: post.latitude ?? 0, longitude: post.longitude ?? 0).environmentObject(authVM),
                isActive: $isMapScreenPresented,
                label: { EmptyView() }
            )
        }
        
    }
    
    //MARK: - ProfilePic
    
    @ViewBuilder
    private func ProfilePic() -> some View {
        VStack {
            NavigationLink(destination: UserProfileScreen(userUid: post.userUid).environmentObject(authVM)) {
                ProfilePicView(profilePic: post.userProfilePic)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    //MARK: - Header
    
    @ViewBuilder
    private func HeaderView() -> some View {
        HStack {
            Text(post.userName ?? "Anonymous")
                .fontWeight(.semibold)
            
            if post.type == .active {
                CircleTimerView(postDate: post.timestamp.timeIntervalSince1970InSeconds, expirationDate: post.expirationDate.timeIntervalSince1970InSeconds)
                    .popover(isPresented: $isTimeLeftPopoverDisplayed) {
                        Text(getTimeLeftText())
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                            .padding([.leading, .trailing], 10)
                            .presentationCompactAdaptation(.popover)
                    }
                    .onTapGesture {
                        isTimeLeftPopoverDisplayed = true
                    }
            } else {
                Text("Expired")
                    .foregroundStyle(.gray)
                    .font(.subheadline)
            }
            
            
            Spacer()
            
            Image(systemName: "ellipsis")
                .foregroundStyle(.gray)
                .popover(isPresented: $isOptionsPopoverDisplayed) {
                    VStack {
                        if post.isFromRecipientUser {
                            Button(role: .destructive, action: {
                                deletePost()
                            }) {
                                Text("Delete Post")
                                Image(systemName: "trash")
                            }
                            .padding()
                        }
                        
                        if !post.isFromRecipientUser {
                            Button(action: {
                                isOptionsPopoverDisplayed = false
                                isReportScreenPresented = true
                            }) {
                                Text("Report Post")
                                Image(systemName: "exclamationmark.bubble")
                            }
                            .padding()
                        }
                    }
                    .presentationCompactAdaptation(.popover)
                }
                .onTapGesture {
                    isOptionsPopoverDisplayed = true
                }
        }
    }
    
    //MARK: - Text
    
    @ViewBuilder
    private func TextView() -> some View {
        Text(post.text)
    }
    
    //MARK: - Location
    
    @ViewBuilder
    private func Location() -> some View {
        HStack {
            Image(systemName: "map")
                .foregroundStyle(.blue)
            
            Text("Posted \(post.formattedDistanceToMe!) meters from you")
                .font(.subheadline)
                .foregroundStyle(.blue)
        }
        .onTapGesture {
            isMapScreenPresented = true
        }
    }
    
    //MARK: - Interactions
    
    @ViewBuilder
    private func InteractionsView() -> some View {
        HStack(spacing: 32) {
            HStack {
                Image(systemName: post.didLike ? "heart.fill" : "heart")
                    .foregroundColor(post.didLike ? .red : .gray)
                    .onTapGesture {
                        Task {
                            let token = try await authVM.getFirebaseToken()
                            if post.didLike {
                                post.didLike = false
                                post.likes -= 1
                                await unlikePublication(publicationId: post.id, token: token)
                            } else {
                                hapticFeedback()
                                post.didLike = true
                                post.likes += 1
                                await likePublication(publicationId: post.id, token: token)
                            }
                        }
                    }
                
                Text(String(post.likes))
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            HStack {
                Image(systemName: "bubble.left")
                    .foregroundColor(.gray)
                
                Text(String(post.comment))
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            if post.isLocationVisible {
                HStack {
                    Image(systemName: "map")
                        .foregroundStyle(.gray)
                    
                    Text("\(post.formattedDistanceToMe!)m")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .onTapGesture {
                    isMapScreenPresented = true
                }
            }
            
            Spacer()
        }
    }
    
    //MARK: - Auxiliary Methods
    
    private func likePublication(publicationId: String, token: String) async {
        let response = await AYServices.shared.likePublication(publicationId: publicationId, token: token)
        
        switch response {
        case .success:
            print("❤️ Publication liked!")
        case .failure(let error):
            print("❌ Error: \(error)")
        }
    }
    
    private func unlikePublication(publicationId: String, token: String) async {
        let response = await AYServices.shared.unlikePublication(publicationId: publicationId, token: token)
        
        switch response {
        case .success:
            print("💔 Publication unliked!")
        case .failure(let error):
            print("❌ Error: \(error)")
        }
    }
    
    private func getTimeLeftText() -> String {
        var timeLeftText = ""
        var timeUnityMeasure = ""
        var pluralModifier = ""
        
        let timeLeftInSeconds = post.expirationDate.timeIntervalSince1970InSeconds - getCurrentDateTimestamp()
        if timeLeftInSeconds < 60 {
            timeUnityMeasure = "second"
            timeLeftText = String(timeLeftInSeconds)
            if timeLeftText != "1" { pluralModifier = "s" }
        } else {
            timeUnityMeasure = "minute"
            timeLeftText = String(Int(timeLeftInSeconds / 60))
            if timeLeftText != "1" { pluralModifier = "s" }
        }
        return timeLeftText + " " + timeUnityMeasure + pluralModifier + " to expire"
    }
}

#Preview {
    PostView(post: .constant(FormattedPost(
        id: "", userUid: "", userProfilePic: "https://www.bloomberglinea.com/resizer/PLUNbQCzVan6SFJ1RQ3CcBj6js8=/600x0/filters:format(webp):quality(75)/cloudfront-us-east-1.images.arcpublishing.com/bloomberglinea/S5ZMXTXZINE2JBQAV7MECJA7KM.jpg",
        userName: "Victor Ordozgoite",
        timestamp: Int(Date().timeIntervalSince1970), expirationDate: Int(Date().timeIntervalSince1970),
        text: "Alguém sabe quando o KFC vai ser inaugurado?? Já faz tempo que eles estão anunciando...", likes: 2, didLike: true, comment: 2, latitude: -3.125847431319091, longitude: -60.022035207661695, distanceToMe: 50.0, isFromRecipientUser: true, isLocationVisible: false)), deletePost: {})
    .environmentObject(AuthenticationViewModel())
}
