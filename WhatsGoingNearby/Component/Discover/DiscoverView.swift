//
//  DiscoverView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 27/10/24.
//

import SwiftUI

struct DiscoverView: View {
    
    @ObservedObject var discoverVM: DiscoverViewModel
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(discoverVM.usersFound) { user in
                        DiscoverUserView(userImageURL: user.imageUrl!, userName: user.displayName, gender: .female, age: user.age)
                            .padding()
                            .padding(.horizontal)
                            .background(
                                Color.white.opacity(0.2)
                                    .background(BlurView())
                            )
                            .cornerRadius(15)
                            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)
                    }
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        discoverVM.isPreferencesViewDisplayed = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .navigationTitle("Discover")
        }
    }
}

struct BlurView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

#Preview {
    DiscoverView(discoverVM: DiscoverViewModel())
}
