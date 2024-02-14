//
//  AuthFlowSegmentedControl.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 13/02/24.
//

import SwiftUI

struct AuthFlowSegmentedControl: View {
    
    @Binding var selectedFilter: AuthenticationFlow
    @Namespace var animation
    
    var body: some View {
        HStack {
            ForEach(AuthenticationFlow.allCases, id: \.rawValue) { item in
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
    AuthFlowSegmentedControl(selectedFilter: .constant(.login))
}
