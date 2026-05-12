//
//  ClusterMapMarker.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 11/05/26.
//

import SwiftUI

struct ClusterMapMarker: View {
    let cluster: MapPostCluster
    
    var body: some View {
        ZStack {
            Circle()
                .fill(.regularMaterial)
                .frame(width: 58, height: 58)
                .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 5)
            
            Circle()
                .stroke(.white.opacity(0.9), lineWidth: 2)
                .frame(width: 58, height: 58)
            
            VStack(spacing: 0) {
                Text("+\(cluster.count)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text("posts")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

//#Preview {
//    ClusterMapMarker()
//}
