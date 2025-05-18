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
    @Binding var isExpanded: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\(text.count)/\(maxPostLength)")
                .foregroundStyle(.gray)
                .font(.subheadline)
            
            Tag()
        }
    }
    
    //MARK: - Tag
    
    @ViewBuilder
    private func Tag() -> some View {
        HStack {
            Label("I want", systemImage: "ellipsis.bubble")
            
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
}

#Preview {
    ExpandedPostSettings(
        maxPostLength: 250,
        text: .constant(""),
        selectedPostTag: .constant(.chilling),
        isExpanded: .constant(true)
    )
}
