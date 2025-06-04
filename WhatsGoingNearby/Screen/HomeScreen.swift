//
//  HomeScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 20/03/25.
//

import SwiftUI

struct HomeScreen: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var socket: SocketService
    @EnvironmentObject var navCoordinator: NavigationCoordinator
    
    /*
     Os ViewModels são instanciados nesta tela parent em vez de dentro de suas respectivas Views. Isso garante a persistência do estado de cada View ao navegar para fora e voltar, utilizando o AYFeatureSelector.
     */
    @StateObject private var placesVM = PlacesViewModel()
    @StateObject private var discoverVM = PeopleViewModel()
    @StateObject private var businessVM = BusinessViewModel()
    @StateObject private var communityVM = CommunityViewModel()
    
    @State private var selectedSection: HomeSection = .places
    
    var body: some View {
        NavigationStack(path: $navCoordinator.path) {
            VStack {
                AYFeatureSelector(selectedSection: $selectedSection)
                
                switch selectedSection {
                case .places:
                    PlacesScreen(placesVM: placesVM)
                case .discover:
                    PeopleScreen(peopleVM: discoverVM)
                case .business:
                    BusinessScreen(businessVM: businessVM)
                case .communities:
                    CommunityListScreen(communityVM: communityVM)
                }
                
                Spacer()
            }
            .navigationDestination(for: AppRoute.self) { destination in
                switch destination {
                case .createPost:
                    CreatePostScreen()
                case .comment(let post):
                    CommentScreen(post: post)
                case .reportDetail(let post):
                    ReportDetailScreen(reportId: post.id)
                case .lostItemDetail(let post):
                    LostItemDetailScreen(lostItemId: post.id)
                case .editPost(let post):
                    EditPostScreen(post: post)
                case .reportIssue(let post):
                    ReportIssueScreen(reportedUserUid: post.userUid, publicationId: post.id, commentId: nil, businessId: nil)
                case .like(let post):
                    LikeScreen(id: post.id, type: .publication)
                case .postMap(let post):
                    if #available(iOS 17.0, *) {
                        NewPostLocationScreen(latitude: post.latitude ?? 0, longitude: post.longitude ?? 0, username: post.username, profilePic: post.userProfilePic)
                    } else {
                        PostLocationScreen(latitude: post.latitude ?? 0, longitude: post.longitude ?? 0)
                    }
                case .createCommunity:
                    CreateCommunityScreen(communityVM: communityVM)
                case .communityMessage(let community):
                    CommunityMessageScreen(community: community)
                case .communityDetail(let community):
                    CommunityDetailScreen(community: community)
                case .createBusiness:
                    PublishBusinessScreen()
                case .editBusiness(let business):
                    EditBusinessView(business: business)
                case .reportBusiness(let business):
                    ReportIssueScreen(reportedUserUid: business.ownerUid, publicationId: nil, commentId: nil, businessId: business.id)
                case .userProfile(let userUid):
                    UserProfileScreen(userUid: userUid)
                case .messages(let chat):
                    MessageScreen(
                        chatId: chat.id,
                        username: chat.chatName,
                        otherUserUid: chat.otherUserUid,
                        chatPic: chat.chatPic,
                        isLocked: chat.isLocked
                    )
                default:
                    EmptyView()
                }
            }
        }
        
    }
}

#Preview {
    HomeScreen()
}
