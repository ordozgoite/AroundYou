//
//  PostSettingsView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 06/04/24.
//

import SwiftUI

struct PostSettingsView: View {
    
    @Binding var tag: PostTag
    @Binding var duration: PostDuration
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Camera()
            
            Tag()
            
            Duration()
            
            Spacer()
        }
    }
    
    //MARK: - Camera
    
    @ViewBuilder
    private func Camera() -> some View {
        HStack {
            Image(systemName: "camera")
                .resizable()
                .scaledToFit()
                .frame(width: 20)
            
            Text("Camera")
                .fontWeight(.semibold)
            
            Spacer()
        }
    }
    
    //MARK: - Tag
    
    @ViewBuilder
    private func Tag() -> some View {
        HStack {
            HStack {
                Image(systemName: "ellipsis.bubble")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20)
                
                Text("Select a Tag")
                    .fontWeight(.semibold)
            }
            
            Spacer()
            
            Menu {
                ForEach(PostTag.allCases, id: \.self) { tag in
                    Button {
                        self.tag = tag
                    } label: {
                        Image(systemName: tag.iconName)
                        Text(tag.title)
                    }
                }
            } label: {
                HStack {
                    Text(tag.title)
                    
                    HStack(spacing: 0) {
                        Image(systemName: tag.iconName)
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
            HStack {
                Image(systemName: "timer")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20)
                
                Text("Post will stay active for")
                    .fontWeight(.semibold)
            }
            
            Spacer()
            
            Menu {
                ForEach(PostDuration.allCases, id: \.self) { duration in
                    Button {
                        self.duration = duration
                    } label: {
                        Text(duration.title)
                    }
                }
            } label: {
                HStack(spacing: 0) {
                    HStack {
                        Text(duration.title)
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
    PostSettingsView(tag: .constant(.chilling), duration: .constant(.oneHour))
}
