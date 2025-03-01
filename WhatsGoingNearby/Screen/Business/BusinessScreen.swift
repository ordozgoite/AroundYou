//
//  BusinessScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 26/02/25.
//

import SwiftUI

struct BusinessScreen: View {
    
    @State private var showcases: [FormattedBusinessShowcase] = FormattedBusinessShowcase.mocks
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    ForEach(showcases) { showcase in
                        BusinessShowcaseView(showcase: showcase)
                    }
                }
            }
            .navigationTitle("Business")
        }
    }
}

#Preview {
    BusinessScreen()
}
