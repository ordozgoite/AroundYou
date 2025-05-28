////
////  MyCommunitiesView.swift
////  WhatsGoingNearby
////
////  Created by Victor Ordozgoite on 20/05/25.
////
//
//import SwiftUI
//
//struct MyCommunitiesView: View {
//    
//    @EnvironmentObject var authVM: AuthenticationViewModel
//    @ObservedObject var communityVM: CommunityViewModel
//    
//    var body: some View {
//        NavigationStack {
//            ZStack {
//                if communityVM.isFetchingUserCommunities {
//                    ProgressView()
//                } else if let myCommunities = communityVM.userCommunities {
//                    if myCommunities.isEmpty {
//                        NoCommunityMessage()
//                    } else {
//                        MyCommunities(myCommunities)
//                    }
//                }
//            }
//            .navigationTitle("My Communities")
//        }
//    }
//    
//    // MARK: - No Community
//    
//    @ViewBuilder
//    private func NoCommunityMessage() -> some View {
//        Text("You don't have any active community.")
//            .bold()
//            .foregroundStyle(.gray)
//    }
//    
//    // MARK: - My Communities
//    
//    @ViewBuilder
//    private func MyCommunities(_ myCommunities: [FormattedCommunity]) -> some View {
//        ZStack {
//            ScrollView {
//                LazyVGrid(
//                    columns: [
//                        GridItem(.flexible(), alignment: .top),
//                        GridItem(.flexible(), alignment: .top),
//                        GridItem(.flexible(), alignment: .top)
//                    ],
//                    spacing: 32
//                ) {
//                    ForEach(myCommunities) { community in
//                        if community.isActive {
//                            ZStack(alignment: .topTrailing) {
//                                CommunityView(
//                                    imageUrl: community.imageUrl,
//                                    imageSize: 64,
//                                    name: community.name,
//                                    isMember: community.isMember,
//                                    isPrivate: community.isPrivate,
//                                    creationDate: community.createdAt.timeIntervalSince1970InSeconds,
//                                    expirationDate: community.expirationDate.timeIntervalSince1970InSeconds
//                                )
//                                
//                                RemoveMediaButton(size: .small)
//                            }
//                            .onTapGesture {
//                                communityVM.selectedCommunityToDelete = community
//                            }
//                        }
//                    }
//                }
//                .padding()
//            }
//        }
//        .alert(item: $communityVM.selectedCommunityToDelete) { community in
//            Alert(
//                title: Text("Delete Community"),
//                message: Text("Do you really want to delete the community \(community.name)?"),
//                primaryButton: .destructive(Text("Delete")) {
//                    Task {
//                        let token = try await authVM.getFirebaseToken()
//                        try await communityVM.deleteCommunity(communityId: community.id, token: token)
//                    }
//                },
//                secondaryButton: .cancel()
//            )
//        }
//
//    }
//}
//
//#Preview {
//    MyCommunitiesView(communityVM: CommunityViewModel())
//        .environmentObject(AuthenticationViewModel())
//}
