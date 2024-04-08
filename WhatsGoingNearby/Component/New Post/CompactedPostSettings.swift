//
//  CompactedPostSettings.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 07/04/24.
//

import SwiftUI

struct CompactedPostSettings: View {
    
    private let maxPostLength = 250
    
    @StateObject var newPostVM: NewPostViewModel
    
    @Binding var isExpanded: Bool
    
    var body: some View {
        HStack {
            HStack(spacing: 16) {
                Tag()
                
                Duration()
            }
            
            Spacer()
            
            Text("\(newPostVM.postText.count)/\(maxPostLength)")
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
                    newPostVM.selectedPostTag = tag
                } label: {
                    Image(systemName: tag.iconName)
                    Text(tag.title)
                }
            }
        } label: {
            HStack(spacing: 0) {
                Image(systemName: newPostVM.selectedPostTag.iconName)
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
                    newPostVM.selectedPostDuration = duration
                } label: {
                    Text(duration.title)
                }
            }
            Text("Post will stay active for:")
        } label: {
            HStack(spacing: 0) {
                HStack {
                    Image(systemName: "clock")
                    Text(newPostVM.selectedPostDuration.abbreviatedTitle)
                }
                .frame(width: 60)
                Image(systemName: "chevron.up.chevron.down")
                    .scaleEffect(0.8)
            }
        }
    }
}

#Preview {
    CompactedPostSettings(newPostVM: NewPostViewModel(), isExpanded: .constant(false))
}
