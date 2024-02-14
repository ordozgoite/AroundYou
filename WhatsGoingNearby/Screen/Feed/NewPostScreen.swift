//
//  NewPostScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import SwiftUI

enum PostVisibility: CaseIterable {
    case identified
    case anonymous
    
    var title: String {
        switch self {
        case .identified:
            return "Identified"
        case .anonymous:
            return "Anonymous"
        }
    }
}

struct NewPostScreen: View {
    
    @Environment(\.presentationMode) var presentationMode
    @State private var postText: String = ""
    @State private var selectedPostVisibility: PostVisibility = .identified
    
    var userName: String {
        switch selectedPostVisibility {
        case .identified:
            return "Victor Ordozgoite"
        case .anonymous:
            return "Anonymous"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            PreferenceView()
            
            TextField("What's going on around?", text: $postText, axis: .vertical)
                .lineLimit(5...10)
            
            Spacer()
        }
        .padding()
        
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Cancel")
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    // create post
                }) {
                    Text("Post")
                }
                .disabled(postText.isEmpty)
            }
        }
        .navigationTitle("Create new post")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    //MARK: - Adjust
    
    @ViewBuilder
    private func PreferenceView() -> some View {
        HStack {
            switch selectedPostVisibility {
            case .identified:
                Image("shaq")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            case .anonymous:
                Image(systemName: "person.crop.circle.badge.questionmark.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
            }
            
            
            VStack {
                Text(userName)
                    .fontWeight(.semibold)
                
                Picker("", selection: $selectedPostVisibility) {
                    ForEach(PostVisibility.allCases, id: \.self) { category in
                        Text(category.title)
                            .tag(category)
                    }
                }
                .pickerStyle(.menu)
                .buttonStyle(.bordered)
            }
        }
    }
}

#Preview {
    NewPostScreen()
}
