//
//  ExpandedPostMapMarker.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 10/05/26.
//

import SwiftUI

struct ExpandedPostMapMarker: View {
    
    let post: MapMarkedPost
    let namespace: Namespace.ID
    let onTap: () -> Void
    
    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HeaderView()
                
                if let text = post.text, !text.isEmpty {
                    Text(text)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                        .transition(.opacity)
                }
                
                if let imageUrl = post.imageUrl,
                   let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .frame(height: 180)
                                .background(.gray.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                            
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 180)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                                .clipped()
                            
                        case .failure:
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 180)
                                .background(.gray.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                            
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .transition(.opacity)
                }
                
                FooterView()
                    .transition(.opacity)
            }
            .padding(14)
            .frame(width: 320)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }
}

private extension ExpandedPostMapMarker {
    
    @ViewBuilder
    func HeaderView() -> some View {
        HStack(alignment: .top, spacing: 10) {
            ProfilePicView(profilePic: post.userProfilePic, size: 46)
                .matchedGeometryEffect(
                    id: "profile-pic-\(post.id)",
                    in: namespace
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(post.username)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .matchedGeometryEffect(
                        id: "username-\(post.id)",
                        in: namespace
                    )
                
                if let tag = post.tag, !tag.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "party.popper")
                            .font(.caption)
                        
                        Text(tag)
                            .font(.subheadline)
                    }
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .transition(.opacity)
        }
    }
    
    @ViewBuilder
    func FooterView() -> some View {
        HStack(spacing: 14) {
            if post.isOwnerFarAway == true {
                Label("Far away", systemImage: "location.slash")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if let duration = post.duration {
                Label("\(duration)h", systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text("Tap to open")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

//#Preview {
//    @Previewable @Namespace var namespace
//    
//    ExpandedPostMapMarker(
//        post: MapMarkedPost.mock,
//        namespace: namespace,
//        onTap: {}
//    )
//}
