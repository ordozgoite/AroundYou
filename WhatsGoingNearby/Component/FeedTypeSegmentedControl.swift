//
//  FeedTypeSegmentedControl.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 26/03/24.
//

import SwiftUI

enum FeedType: Int, Equatable, CaseIterable {
    case old
    case now
    
    var title: LocalizedStringKey {
        switch self {
        case .old:
            return "Timeline"
        case .now:
            return "Now"
        }
    }
}

struct FeedTypeSegmentedControl: View {
    
    @Binding var selectedFilter: FeedType
    @Namespace var animation
    
    var body: some View {
        HStack(spacing: 50) {
            ForEach(FeedType.allCases, id: \.rawValue) { item in
                Spacer()
                VStack {
                    Text(item.title)
                        .fontWeight(selectedFilter == item ? .semibold : .regular)
                        .foregroundColor(selectedFilter == item ? .accent : .gray)
                    
                    if selectedFilter == item {
                        Capsule()
                            .foregroundColor(.accent)
                            .frame(width: 28, height: 3)
                            .matchedGeometryEffect(id: "filter", in: animation)
                    } else {
                        Capsule()
                            .foregroundColor(Color(.clear))
                            .frame(width: 28, height: 3)
                    }
                }
                .onTapGesture {
                    withAnimation {
                        self.selectedFilter = item
                    }
                }
            }
            Spacer()
        }
//        .overlay(Divider().offset(x: 0, y: 16))
        .padding([.leading, .trailing], 32)
        .padding(.top, 8)
    }
}

#Preview {
    FeedTypeSegmentedControl(selectedFilter: .constant(.now))
}

