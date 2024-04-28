//
//  CompactedPostSettings.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 07/04/24.
//

import SwiftUI

struct CompactedPostSettings: View {
    
    let maxPostLength: Int
    @Binding var text: String
    @Binding var selectedPostTag: PostTag
    @Binding var selectedPostDuration: PostDuration
    @Binding var isExpanded: Bool
    
    var body: some View {
        HStack {
            HStack(spacing: 16) {
                Tag()
                
                Duration()
            }
            
            Spacer()
            
            Text("\(text.count)/\(maxPostLength)")
                .foregroundStyle(.gray)
                .font(.subheadline)
        }
    }
    
    //MARK: - Tag
    
    @ViewBuilder
    private func Tag() -> some View {
        Menu {
            ForEach(PostTag.allCases, id: \.self) { tag in
                Button {
                    selectedPostTag = tag
                } label: {
                    Image(systemName: tag.iconName)
                    Text(tag.title)
                }
            }
        } label: {
            HStack(spacing: 0) {
                Image(systemName: selectedPostTag.iconName)
                Image(systemName: "chevron.up.chevron.down")
                    .scaleEffect(0.8)
            }
        }
    }
    
    //MARK: - Duration
    
    @ViewBuilder
    private func Duration() -> some View {
        Menu {
            ForEach(PostDuration.allCases, id: \.self) { duration in
                Button {
                    selectedPostDuration = duration
                } label: {
                    Text(duration.title)
                }
            }
            Text("Post will stay active for:")
        } label: {
            HStack(spacing: 0) {
                HStack {
                    Image(systemName: "clock")
                    Text(selectedPostDuration.abbreviatedTitle)
                        .lineLimit(1)
                }
//                .frame(width: 60)
                Image(systemName: "chevron.up.chevron.down")
                    .scaleEffect(0.8)
            }
        }
    }
}

#Preview {
    CompactedPostSettings(
        maxPostLength: 250,
        text: .constant(""),
        selectedPostTag: .constant(.buy),
        selectedPostDuration: .constant(.oneHour),
        isExpanded: .constant(false)
    )
}
