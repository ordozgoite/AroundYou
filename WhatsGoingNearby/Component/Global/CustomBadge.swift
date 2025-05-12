//
//  CustomBadge.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 14/02/25.
//

import SwiftUI

struct CustomBadge: View {
    let count: Int

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if count != 0 {
                Color.clear
                Text(getText(fromCount: count))
                    .foregroundStyle(.white)
                    .font(.system(size: 12))
                    .padding(5)
                    .background(Color.red)
                    .clipShape(Circle())
                // custom positioning in the top-right corner
                    .alignmentGuide(.top) { $0[.bottom] - $0.height * 0.5 }
                    .alignmentGuide(.trailing) { $0[.trailing] - $0.width * 0.25 }
            }
        }
    }
    
    private func getText(fromCount count: Int) -> String {
        return count > 9 ? "+9" : String(count)
    }
}

#Preview {
    NavigationLink(destination: Text("teste")) {
        Image(systemName: "bubble")
    }
    .overlay(CustomBadge(count: 99))
}
