//
//  ClusterMapMarker.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 11/05/26.
//

import SwiftUI

struct ClusterMapMarker: View {

    let cluster: MapPostCluster

    // Um pouco maior que o marcador individual, para que o agrupamento se destaque no mapa.
    private let markerSize: CGFloat = 56
    private let avatarSize: CGFloat = 24

    var body: some View {
        MapMarkerPin(diameter: markerSize) {
            countBadge
        } content: { diameter in
            avatarComposition(diameter: diameter)
                .frame(width: diameter, height: diameter)
                .background(.ultraThinMaterial)
        }
    }

    @ViewBuilder
    private func avatarComposition(diameter: CGFloat) -> some View {
        // Cada entrada da amostra é um autor, e `nil` quer dizer "sem foto de perfil", não "sem
        // autor" — quem não tem foto entra no mosaico com o avatar padrão. Contar só as fotos
        // apagaria do marcador justamente esses autores.
        let authors = Array(cluster.previewUserProfilePics.prefix(4))

        if authors.count <= 1 {
            singleAuthorAvatar(
                profilePic: authors.first ?? nil,
                diameter: diameter
            )
        } else {
            avatarMosaic(authors: authors)
        }
    }

    /// Autor único: o avatar ocupa o marcador inteiro, como no marcador de publicação individual.
    /// Quem diz que ali há mais de uma publicação é o badge com o contador.
    @ViewBuilder
    private func singleAuthorAvatar(
        profilePic: String?,
        diameter: CGFloat
    ) -> some View {
        if let profilePic {
            ProfilePicView(profilePic: profilePic, size: diameter)
                .frame(width: diameter, height: diameter)
                .clipShape(Circle())
                .id(profilePic)
        } else {
            Circle()
                .fill(.gray.opacity(0.25))
                .frame(width: diameter, height: diameter)
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.system(size: diameter * 0.42))
                        .foregroundStyle(.secondary)
                }
        }
    }

    private func avatarMosaic(authors: [String?]) -> some View {
        ZStack {
            switch authors.count {
            case 2:
                ZStack {
                    clusterAvatar(profilePic: authors[0], size: 30)
                        .offset(x: -8, y: 0)
                        .zIndex(1)

                    clusterAvatar(profilePic: authors[1], size: 30)
                        .offset(x: 8, y: 0)
                        .zIndex(0)
                }

            case 3:
                ZStack {
                    clusterAvatar(profilePic: authors[0], size: 27)
                        .offset(x: 0, y: -11)
                        .zIndex(2)

                    clusterAvatar(profilePic: authors[1], size: 25)
                        .offset(x: -12, y: 11)
                        .zIndex(1)

                    clusterAvatar(profilePic: authors[2], size: 25)
                        .offset(x: 12, y: 11)
                        .zIndex(0)
                }

            default:
                ZStack {
                    clusterAvatar(profilePic: authors[0], size: avatarSize)
                        .offset(x: -10, y: -10)

                    clusterAvatar(profilePic: authors[1], size: avatarSize)
                        .offset(x: 10, y: -10)

                    clusterAvatar(profilePic: authors[2], size: avatarSize)
                        .offset(x: -10, y: 10)

                    clusterAvatar(profilePic: authors[3], size: avatarSize)
                        .offset(x: 10, y: 10)
                }
            }
        }
    }

    private var countBadge: some View {
        MapMarkerBadge {
            Text(cluster.countText)
                .font(.system(size: 11, weight: .bold))
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
