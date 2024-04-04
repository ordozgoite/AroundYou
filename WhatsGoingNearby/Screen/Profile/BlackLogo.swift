//
//  TEse.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 02/04/24.
//

import SwiftUI

struct BlackLogo: View {
    var body: some View {
        ZStack {
            Image("logo")
                .resizable()
                .scaledToFit()
                .colorMultiply(.gray)
            
            Color.black
                .mask(
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                )
        }
    }
}

#Preview {
    BlackLogo()
}
