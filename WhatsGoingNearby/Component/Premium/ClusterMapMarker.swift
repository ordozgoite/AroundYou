//
//  ClusterMapMarker.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 11/05/26.
//

import SwiftUI

struct ClusterMapMarker: View {
    
    let cluster: MapPostCluster
    
    private let markerSize: CGFloat = 52
    private let mainAvatarSize: CGFloat = 34
    private let avatarSize: CGFloat = 24
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: markerSize, height: markerSize)
                .shadow(color: .black.opacity(0.16), radius: 8, x: 0, y: 4)
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.95), lineWidth: 2)
                }
            
            avatarComposition
                .frame(width: markerSize, height: markerSize)
                .clipShape(Circle())
            
            countBadge
                .offset(x: 5, y: 4)
        }
    }
    
    private var avatarComposition: some View {
        let avatars = Array(cluster.previewUserProfilePics.prefix(4))
        
        return ZStack {
            switch avatars.count {
            case 0:
                placeholderAvatar(size: mainAvatarSize)
                
            case 1:
                clusterAvatar(profilePic: avatars[0], size: mainAvatarSize)
                
            case 2:
                ZStack {
                    clusterAvatar(profilePic: avatars[0], size: 30)
                        .offset(x: -8, y: 0)
                        .zIndex(1)
                    
                    clusterAvatar(profilePic: avatars[1], size: 30)
                        .offset(x: 8, y: 0)
                        .zIndex(0)
                }
                
            case 3:
                ZStack {
                    clusterAvatar(profilePic: avatars[0], size: 27)
                        .offset(x: 0, y: -11)
                        .zIndex(2)
                    
                    clusterAvatar(profilePic: avatars[1], size: 25)
                        .offset(x: -12, y: 11)
                        .zIndex(1)
                    
                    clusterAvatar(profilePic: avatars[2], size: 25)
                        .offset(x: 12, y: 11)
                        .zIndex(0)
                }
                
            default:
                ZStack {
                    clusterAvatar(profilePic: avatars[0], size: avatarSize)
                        .offset(x: -10, y: -10)
                    
                    clusterAvatar(profilePic: avatars[1], size: avatarSize)
                        .offset(x: 10, y: -10)
                    
                    clusterAvatar(profilePic: avatars[2], size: avatarSize)
                        .offset(x: -10, y: 10)
                    
                    clusterAvatar(profilePic: avatars[3], size: avatarSize)
                        .offset(x: 10, y: 10)
                }
            }
        }
    }
    
    private var countBadge: some View {
        Text(cluster.countText)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(.black.opacity(0.8))
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(.white.opacity(0.95), lineWidth: 1)
            }
    }
    
    @ViewBuilder
    private func clusterAvatar(profilePic: String?, size: CGFloat) -> some View {
        if let profilePic {
            ProfilePicView(profilePic: profilePic, size: size)
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(.white, lineWidth: 1.2)
                }
                .id(profilePic)
        } else {
            placeholderAvatar(size: size)
        }
    }
    
    private func placeholderAvatar(size: CGFloat) -> some View {
        Circle()
            .fill(.gray.opacity(0.25))
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.42))
                    .foregroundStyle(.secondary)
            }
            .overlay {
                Circle()
                    .stroke(.white, lineWidth: 1.2)
            }
    }
}

private extension MapPostCluster {
    
    var countText: String {
        if count > 99 {
            return "99+"
        }
        
        return "\(count)"
    }
}

//#Preview {
//    ClusterMapMarker()
//}
