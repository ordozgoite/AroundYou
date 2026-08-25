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

    private let markerSize: CGFloat = 46

    var body: some View {
        VStack(spacing: 4) {
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

            MapMarkerPin(diameter: markerSize) {
                if post.hasApproximateLocation {
                    approximateLocationBadge
                }
            } content: { diameter in
                ProfilePicView(profilePic: post.userProfilePic, size: diameter)
                    .id("\(post.id)-\(post.userProfilePic ?? "nil")")
                    .matchedGeometryEffect(
                        id: "profile-pic-\(post.id)",
                        in: namespace
                    )
            }
        }
    }

    private var approximateLocationBadge: some View {
        MapMarkerBadge(horizontalPadding: 4, verticalPadding: 4) {
            Image(systemName: "location.slash.fill")
                .font(.system(size: 9, weight: .bold))
        }
        .accessibilityLabel(Text("Approximate location"))
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
