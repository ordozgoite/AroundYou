//
//  AuthenticatedScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import SwiftUI

struct AuthenticatedScreen: View {
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    
    var body: some View {
        if authVM.authenticationState == .authenticated {
            PreparingSessionScreen()
                .environmentObject(authVM)
        } else {
            AuthenticationScreen()
                .environmentObject(authVM)
        }
    }
}

#Preview {
    AuthenticatedScreen()
}
