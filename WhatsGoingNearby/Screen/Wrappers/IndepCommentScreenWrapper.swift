//
//  IndepCommentScreenWrapper.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 26/02/25.
//

import SwiftUI

struct IndepCommentScreenWrapper: View {
    let postId: String
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            IndepCommentScreen(postId: postId)
                .navigationBarItems(leading: Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }, label: {
                    Image(systemName: "xmark")
                }))
        }
    }
}
