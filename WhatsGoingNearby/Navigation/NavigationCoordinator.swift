//
//  NavigationCoordinator.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 28/05/25.
//

import Foundation

enum AppRoute: Hashable { // Type 'AppRoute' does not conform to protocol 'Identifiable'
    // Auth
    case forgotPassword
    
    // Posts
    case createPost
    case comment(FormattedPost)
    case reportDetail(FormattedPost)
    case lostItemDetail(FormattedPost)
    case editPost(FormattedPost)
    case reportIssue(FormattedPost)
    case postMap(FormattedPost)
    case like(FormattedPost)
    case userProfile(String)
    case postDetail(String)
    
    // Explore
    case exploreMap
    case clusterPosts(MapClusterBounds)
    
    // People
    
    // Communities
    case createCommunity
    case communityMessage(FormattedCommunity)
    case communityDetail(FormattedCommunity)
    
    // Businesses
    case createBusiness
    case editBusiness(FormattedBusinessShowcase)
    case reportBusiness(FormattedBusinessShowcase)
    case businessMap(FormattedBusinessShowcase)
    
    // Chats
    case messages(FormattedChat)
    
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

    /// Substitui a pilha inteira, para quando o destino precisa ficar logo acima da raiz.
    ///
    /// A comparação evita reemitir o `path` quando ele já é o pedido: sem ela, um destino
    /// repetido reconstruiria a tela que já está na frente do usuário.
    func setStack(_ routes: [AppRoute]) {
        guard path != routes else { return }
        path = routes
    }

    /// `chatId` da conversa no topo da pilha, quando há uma.
    ///
    /// A conversa é identificada pelo id, e não pela instância de `FormattedChat`: o mesmo
    /// chat chega com campos diferentes conforme a origem (lista, perfil ou notificação).
    var topChatId: String? {
        guard let last = path.last, case let .messages(chat) = last else { return nil }
        return chat.id
    }
}
