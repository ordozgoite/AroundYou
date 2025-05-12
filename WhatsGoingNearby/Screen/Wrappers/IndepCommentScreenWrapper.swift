//
//  IndepCommentScreenWrapper.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 26/02/25.
//

import SwiftUI

struct IndepCommentScreenWrapper: View {
    let postId: String
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var socket: SocketService
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            IndepCommentScreen(postId: postId, locationManager: locationManager, socket: socket)
                .navigationBarItems(leading: Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }, label: {
                    Image(systemName: "xmark")
                }))
        }
    }
}
