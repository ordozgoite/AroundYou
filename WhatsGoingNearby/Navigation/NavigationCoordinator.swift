//
//  NavigationCoordinator.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 28/05/25.
//

import Foundation

enum AppRoute: Hashable {
    // Posts
    case createPost
    case comment(FormattedPost)
    case reportDetail(FormattedPost)
    case lostItemDetail(FormattedPost)
    case editPost(FormattedPost)
    case reportIssue(FormattedPost)
    case map(FormattedPost)
    case like(FormattedPost)
    
    // People
    
    // Communities
    case createCommunity
    case communityMessage(FormattedCommunity)
    case communityDetail(FormattedCommunity)
    
    // Businesses
    case createBusiness
    
    // Account
    case editProfile
    case settings
}

@MainActor
class NavigationCoordinator: ObservableObject {
    @Published var path: [AppRoute] = []
    
    func navigate(to route: AppRoute) {
        path.append(route)
    }
    
    func goBack() {
        _ = path.popLast()
    }
    
    func goToRoot() {
        path.removeAll()
    }
}
