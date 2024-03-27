//
//  PostTypeSegmentedControl.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 16/02/24.
//

import SwiftUI

enum PostHistoryOption: Int, CaseIterable, Codable  {
    case all
    case active
    case inactive
    
    var title: LocalizedStringKey {
        switch self {
        case .all:
            return "All"
        case .active:
            return "Actives"
        case .inactive:
            return "Inactives"
        }
    }
}

struct PostTypeSegmentedControl: View {
    
    @Binding var selectedFilter: PostHistoryOption
    @Namespace var animation
    
    var body: some View {
        HStack {
            ForEach(PostHistoryOption.allCases, id: \.rawValue) { item in
                VStack {
                    Text(item.title)
                        .font(.subheadline)
                        .fontWeight(selectedFilter == item ? .semibold : .regular)
                        .foregroundColor(selectedFilter == item ? .blue : .gray)
                    
                    if selectedFilter == item {
                        Capsule()
                            .foregroundColor(.blue)
                            .frame(height: 3)
                        
                            .matchedGeometryEffect(id: "filter", in: animation)
                    } else {
                        Capsule()
                            .foregroundColor(Color(.clear))
                            .frame(height: 3)
                    }
                }
                .onTapGesture {
                    withAnimation {
                        self.selectedFilter = item
                    }
                }
            }
        }
        .overlay(Divider().offset(x: 0, y: 16))
    }
}

#Preview {
    PostTypeSegmentedControl(selectedFilter: .constant(.all))
}
