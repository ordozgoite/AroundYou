//
//  FeedScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import SwiftUI

struct FeedScreen: View {
    
    @ObservedObject private var feedVM = FeedViewModel()
    
    var body: some View {
        NavigationStack {
            VStack {
                if feedVM.isLoading {
                    LoadingView()
                } else {
                    PostsView()
                }
            }
            
            .toolbar {
                ToolbarItem {
                    NavigationLink(destination: NewPostScreen()) {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .navigationTitle("Around you 🌐")
        }
        .onAppear {
            feedVM.getPostsNearBy()
        }
    }
    
    //MARK: - Loading
    
    @ViewBuilder
    private func LoadingView() -> some View {
        VStack {
            AYProgressView()
            
            Text("Looking around you...")
                .foregroundStyle(.gray)
                .fontWeight(.semibold)
        }
    }
    
    //MARK: - Posts View
    
    @ViewBuilder
    private func PostsView() -> some View {
        ScrollView {
            ForEach(feedVM.posts) { post in
                PostView(post: post)
                    .padding()
            }
        }
        .refreshable {
            feedVM.isLoading = true
            print("🚀 Refreshed!")
        }
    }
}

#Preview {
    FeedScreen()
}
