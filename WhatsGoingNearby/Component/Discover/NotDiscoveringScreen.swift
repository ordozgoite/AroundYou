//
//  NotDiscoveringScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 23/05/25.
//

import SwiftUI

struct NotDiscoveringScreen: View {
    @EnvironmentObject var authVM: AuthenticationViewModel
    @ObservedObject var peopleVM: PeopleViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                if peopleVM.isLoading {
                    ProgressView()
                        .frame(maxHeight: .infinity, alignment: .center)
                } else if !authVM.isUserDiscoverable {
                    ActivateDiscoverView(isLoading: $peopleVM.isActivatingDiscover) {
                        Task {
                            try await activateDiscover()
                        }
                    }
                }
            }
            .toolbar {
                /*
                 Gambiarra para que a NavBar fique maior e não cause aquele efeito de deslocamento da AYFeatureSelector ao clicar na aba People.
                 Isso acontecia porque as demais telas têm um botão na NavBar e a PeopleScreen, ao ser carregada pela primeira vez, não exibe nenhum. Ela só tem um botão (botão de filtro) na DiscoverView, quando o usuário já está 'Discoverable'.
                 */
                Button {} label: { Image(systemName: "") }
            }
        }
    }
}

// MARK: - Private Methods

extension NotDiscoveringScreen {
    private func activateDiscover() async throws {
        let token = try await authVM.getFirebaseToken()
        do {
            try await peopleVM.activateUserDiscoverability(token: token)
            authVM.isUserDiscoverable = true
        } catch {
            print("❌ Error trying to activate Discover.")
        }
    }
}

#Preview {
    NotDiscoveringScreen(peopleVM: PeopleViewModel())
        .environmentObject(AuthenticationViewModel())
}
