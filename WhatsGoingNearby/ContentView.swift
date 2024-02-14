//
//  ContentView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        AuthenticatedScreen()
            .environmentObject(AuthenticationViewModel())
    }
}

#Preview {
    ContentView()
}
