//
//  AYFeatureSelector.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 20/03/25.
//

import SwiftUI

enum HomeSection: String, CaseIterable {
    case posts = "Posts"
    case discover = "People"
    case business = "Business"
    case urgent = "Urgent"
    case communities = "Communities"
    
    var iconName: String {
        return switch self {
        case .posts:
            "quote.bubble"
        case .discover:
            "heart"
        case .business:
            "storefront"
        case .urgent:
            "light.beacon.max"
        case .communities:
            "person.3"
        }
    }
    
    var color: Color {
        return switch self {
        case .posts:
                .blue
        case .discover:
                .pink
        case .business:
                .orange
        case .urgent:
                .red
        case .communities:
                .brown
        }
    }
}

import SwiftUI

struct AYFeatureSelector: View {
    @State private var selectedSection: HomeSection = .posts
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(HomeSection.allCases, id: \.self) { section in
                    ItemView(forSection: section)
                        .animation(.spring(), value: selectedSection) // Animação aplicada às mudanças de estado
                }
            }
        }
    }
    
    // MARK: - Section Item
    
    @ViewBuilder
    private func ItemView(forSection section: HomeSection) -> some View {
        HStack {
            Image(systemName: section.iconName)
                .resizable()
                .scaledToFit()
                .frame(height: 24)
                .foregroundColor(selectedSection == section ? .white : .gray)
                .transition(.opacity)
            
            if selectedSection == section {
                Text(section.rawValue)
                    .foregroundStyle(.white)
                    .transition(.move(edge: .trailing).combined(with: .opacity)) // Animação ao aparecer/desaparecer
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(selectedSection == section ? section.color : .gray.opacity(0.2))
                .animation(.easeInOut, value: selectedSection)
        )
        .onTapGesture {
            withAnimation(.spring()) {
                self.selectedSection = section
            }
        }
    }
}

#Preview {
    AYFeatureSelector()
}
