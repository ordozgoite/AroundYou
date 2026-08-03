//
//  PostMapMarker.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 10/05/26.
//

import SwiftUI

struct PostMapMarker: View {
    
    let post: MapMarkedPost
    let namespace: Namespace.ID
    
    var body: some View {
        VStack(spacing: 4) {
            ProfilePicView(profilePic: post.userProfilePic, size: 46)
                .id("\(post.id)-\(post.userProfilePic ?? "nil")")
                .matchedGeometryEffect(
                    id: "profile-pic-\(post.id)",
                    in: namespace
                )
            
            Text(post.username)
                .font(.caption2)
                .fontWeight(.medium)
                .lineLimit(1)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .matchedGeometryEffect(
                    id: "username-\(post.id)",
                    in: namespace
                )
        }
    }
}

//#Preview {
//    @Previewable @Namespace var namespace
//    
//    PostMapMarker(
//        post: MapMarkedPost.mock,
//        namespace: namespace
//    )
//}
