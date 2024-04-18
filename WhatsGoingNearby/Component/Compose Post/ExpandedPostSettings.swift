//
//  PostSettings.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 07/04/24.
//

import SwiftUI

struct ExpandedPostSettings: View {
    
    let maxPostLength: Int
    @Binding var text: String
    @Binding var selectedPostTag: PostTag
    @Binding var selectedPostDuration: PostDuration
    @Binding var isExpanded: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\(text.count)/\(maxPostLength)")
                .foregroundStyle(.gray)
                .font(.subheadline)
            
            Tag()
            
            Duration()
        }
    }
    
    //MARK: - Tag
    
    @ViewBuilder
    private func Tag() -> some View {
        HStack {
            Label("I am", systemImage: "ellipsis.bubble")
            
            Spacer()
            
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
                HStack {
                    Text(selectedPostTag.title)
                    
                    HStack(spacing: 0) {
                        Image(systemName: selectedPostTag.iconName)
                        Image(systemName: "chevron.up.chevron.down")
                            .scaleEffect(0.8)
                    }
                }
            }
        }
    }
    
    //MARK: - Duration
    
    @ViewBuilder
    private func Duration() -> some View {
        HStack {
            Label("Post will stay active for", systemImage: "timer")
            
            Spacer()
            
            Menu {
                ForEach(PostDuration.allCases, id: \.self) { duration in
                    Button {
                        selectedPostDuration = duration
                    } label: {
                        Text(duration.title)
                    }
                }
            } label: {
                HStack(spacing: 0) {
                    HStack {
                        Text(selectedPostDuration.title)
                    }
                    .frame(width: 60)
                    Image(systemName: "chevron.up.chevron.down")
                        .scaleEffect(0.8)
                }
            }
        }
    }
}

#Preview {
    ExpandedPostSettings(
        maxPostLength: 250,
        text: .constant(""),
        selectedPostTag: .constant(.buy),
        selectedPostDuration: .constant(.oneHour),
        isExpanded: .constant(true)
    )
}
