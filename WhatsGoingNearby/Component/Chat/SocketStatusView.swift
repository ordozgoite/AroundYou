//
//  SocketStatusView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 25/05/24.
//

import SwiftUI

struct SocketStatusView: View {
    
    @ObservedObject var socket: SocketService
    @State private var isPopoverDisplayed: Bool = false
    
    var body: some View {
        VStack {
            switch socket.status {
            case .connected:
                Circle().fill(.green)
                    .frame(width: 8, height: 8, alignment: .center)
            case .connecting:
                ProgressView()
            case .disconnected:
                Circle().fill(.red)
                    .frame(width: 8, height: 8, alignment: .center)
            }
        }
        .frame(width: 32, height: 32, alignment: .center)
        .popover(isPresented: $isPopoverDisplayed) {
            Text(getSocketStatusMessage())
                .font(.subheadline)
                .foregroundStyle(.gray)
                .padding([.leading, .trailing], 10)
                .presentationCompactAdaptation(.popover)
        }
        .onTapGesture {
            isPopoverDisplayed = true
        }
    }
    
    private func getSocketStatusMessage() -> LocalizedStringKey {
        return switch socket.status {
        case .connected:
            "You are connected 😃"
        case .connecting:
            "Connecting..."
        case .disconnected:
            "You are disconnected 😔"
        }
    }
}

#Preview {
    SocketStatusView(socket: SocketService())
}
